# frozen_string_literal: true

require "rails_helper"

RSpec.describe Fcm::Client do
  let(:authorizer) do
    double("authorizer", access_token: "access-token", expired?: false, fetch_access_token!: nil)
  end
  let(:service_account_json) { '{"project_id":"proj-123"}' }

  before do
    # authorizer é memoizado na classe entre chamadas — zera pra cada exemplo.
    described_class.instance_variable_set(:@authorizer, nil)
    allow(Rails.application.credentials).to receive(:dig)
      .with(:fcm, :service_account_json).and_return(service_account_json)
    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(authorizer)
  end

  # Resposta real da subclasse certa para que `is_a?(Net::HTTPSuccess)` funcione;
  # body é stubado porque não veio de um socket.
  def http_response(klass, code, body: nil)
    response = klass.new("1.1", code, "msg")
    allow(response).to receive(:body).and_return(body) if body
    response
  end

  def stub_http(response)
    # yield de um http fake para o bloco `Net::HTTP.start(...) { |http| http.request(...) }`,
    # devolvendo a resposta escolhida.
    http = double("http", request: response)
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
  end

  def send!
    described_class.send_notification(token: "device-tok", title: "Oi", body: "Olá")
  end

  describe ".send_notification" do
    it "posts to FCM and returns true on success" do
      stub_http(http_response(Net::HTTPOK, "200"))

      expect(send!).to be(true)
      expect(Google::Auth::ServiceAccountCredentials).to have_received(:make_creds)
    end

    it "raises StaleToken when FCM returns 404" do
      stub_http(http_response(Net::HTTPNotFound, "404", body: "not found"))

      expect { send! }.to raise_error(Fcm::Client::StaleToken)
    end

    it "raises StaleToken when the body reports an UNREGISTERED token" do
      stub_http(http_response(Net::HTTPBadRequest, "400", body: '{"error":"UNREGISTERED"}'))

      expect { send! }.to raise_error(Fcm::Client::StaleToken)
    end

    it "raises Error on any other non-success response" do
      stub_http(http_response(Net::HTTPInternalServerError, "500", body: "boom"))

      expect { send! }.to raise_error(Fcm::Client::Error, /500.*boom/)
    end

    it "raises NotConfigured when the service account is missing" do
      allow(Rails.application.credentials).to receive(:dig)
        .with(:fcm, :service_account_json).and_return(nil)

      expect { send! }.to raise_error(Fcm::Client::NotConfigured, "FCM service account not configured")
    end
  end

  describe "access token handling" do
    before { stub_http(http_response(Net::HTTPOK, "200")) }

    it "fetches a token when none is cached" do
      allow(authorizer).to receive(:access_token).and_return(nil)

      send!

      expect(authorizer).to have_received(:fetch_access_token!)
    end

    it "fetches a token when the cached one is expired" do
      allow(authorizer).to receive(:expired?).and_return(true)

      send!

      expect(authorizer).to have_received(:fetch_access_token!)
    end

    it "reuses a valid cached token without refreshing" do
      send!

      expect(authorizer).not_to have_received(:fetch_access_token!)
    end
  end

  it "memoizes the authorizer and project id across calls on the same client" do
    stub_http(http_response(Net::HTTPOK, "200"))
    client = described_class.new

    2.times { client.send_notification(token: "device-tok", title: "Oi", body: "Olá") }

    expect(Google::Auth::ServiceAccountCredentials).to have_received(:make_creds).once
  end
end
