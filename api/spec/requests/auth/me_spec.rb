# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth Me", type: :request do
  describe "GET /api/v1/auth/me" do
    let(:user) { create(:user, username: "johndoe") }
    let(:role) { create(:role, name: "user") }
    let(:permission) { create(:permission, resource: "journey", action: "view") }

    before do
      role.permissions << permission
      user.roles << role
    end

    context "with a valid Bearer token" do
      let(:token) { JsonWebToken.encode(user_id: user.id) }

      it "returns 200 with the current user and flat resource:action permissions" do
        get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        expect(json_response.keys).to eq(%w[user])
        expect(json_response["user"]).to eq(
          "id" => user.id,
          "username" => "johndoe",
          "name" => user.name,
          "email" => user.email,
          "tracks_journey" => true,
          "permissions" => [ "journey:view" ],
          "imageBase64" => nil
        )
      end
    end

    context "without a token" do
      it "returns 401" do
        get "/api/v1/auth/me"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end

    context "with an invalid token" do
      it "returns 401" do
        get "/api/v1/auth/me", headers: { "Authorization" => "Bearer not.a.jwt" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end

    context "with an expired token" do
      let(:token) { JsonWebToken.encode({ user_id: user.id }, 1.hour.ago) }

      it "returns 401" do
        get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
