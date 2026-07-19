# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::LoginService do
  let(:password) { "Password123!" }
  let!(:user) { create(:user, username: "fulano", password: password, password_confirmation: password) }

  describe ".call" do
    context "with valid credentials" do
      subject(:result) { described_class.call(username: "fulano", password: password) }

      it "returns the authenticated user, a token and an expiration" do
        expect(result.user).to eq(user)
        expect(result.token).to be_present
        expect(result.expires_at).to be_within(1.minute).of(24.hours.from_now)
      end

      it "encodes the user id into the token" do
        expect(JsonWebToken.decode(result.token)[:user_id]).to eq(user.id)
      end
    end

    shared_examples "invalid credentials" do
      it "raises Auth::InvalidCredentials with a 401 status" do
        expect { call }.to raise_error(Auth::InvalidCredentials) do |error|
          expect(error.message).to eq("Invalid username or password")
          expect(error.status).to eq(:unauthorized)
        end
      end
    end

    context "with a wrong password" do
      let(:call) { described_class.call(username: "fulano", password: "wrong-password") }
      include_examples "invalid credentials"
    end

    context "with an unknown username" do
      let(:call) { described_class.call(username: "ghost", password: password) }
      include_examples "invalid credentials"
    end

    context "with a soft-deleted user" do
      before { user.soft_delete }

      let(:call) { described_class.call(username: "fulano", password: password) }
      include_examples "invalid credentials"
    end
  end
end
