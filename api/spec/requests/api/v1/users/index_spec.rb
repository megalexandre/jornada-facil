# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users Index", type: :request do
  describe "GET /api/v1/users" do
    let(:user) { create(:user, name: "Carla") }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the users:view permission" do
      before { grant("users", "view") }

      it "returns all users ordered by name, including the requester" do
        bruno = create(:user, name: "Bruno")
        ana = create(:user, name: "Ana")

        get "/api/v1/users", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response.map { |u| u["name"] }).to eq(%w[Ana Bruno Carla])
        expect(json_response.first).to eq(serialized(ana))
      end

      it "excludes soft-deleted users" do
        deleted = create(:user, name: "Deletado")
        deleted.soft_delete

        get "/api/v1/users", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response.map { |u| u["id"] }).to eq([ user.id.to_s ])
      end

      it "includes inactive users when include_inactive is set" do
        deleted = create(:user, name: "Deletado")
        deleted.soft_delete

        get "/api/v1/users", params: { include_inactive: true }, headers: headers

        expect(response).to have_http_status(:ok)
        deleted_row = json_response.find { |u| u["id"] == deleted.id.to_s }
        expect(deleted_row["active"]).to be(false)
      end

      it "filters to journey trackers when tracks_journey is set" do
        create(:user, :no_journey, name: "Gestor")

        get "/api/v1/users", params: { tracks_journey: true }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response.map { |u| u["name"] }).not_to include("Gestor")
        expect(json_response).to all(include("tracks_journey" => true))
      end
    end

    context "without the users:view permission" do
      before { grant("journey", "view") }

      it "returns 403 forbidden" do
        get "/api/v1/users", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        get "/api/v1/users"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  def serialized(record)
    {
      "id" => record.id.to_s,
      "name" => record.name,
      "username" => record.username,
      "email" => record.email,
      "tracks_journey" => record.tracks_journey,
      "active" => record.deleted_at.nil?
    }
  end
end
