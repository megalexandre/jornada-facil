# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users Show", type: :request do
  describe "GET /api/v1/users/:id" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }

    def grant_users_view(grantee)
      role = create(:role, name: "users_viewer")
      role.permissions << create(:permission, resource: "users", action: "view")
      grantee.roles << role
    end

    context "when authenticated with the users:view permission" do
      before { grant_users_view(user) }

      it "returns the user with complete data" do
        get "/api/v1/users/#{user.id}", headers: { "Authorization" => "Bearer #{auth_token}" }

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq(
          "id" => user.id.to_s,
          "name" => user.name,
        )
      end
    end

    context "when authenticated without the users:view permission" do
      it "returns 403 forbidden" do
        get "/api/v1/users/#{user.id}", headers: { "Authorization" => "Bearer #{auth_token}" }

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/#{user.id}"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end

    context "with invalid token" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/#{user.id}", headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end

    context "with malformed token" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/#{user.id}", headers: { "Authorization" => "Bearer malformed.token.here" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end

    context "when user does not exist" do
      before { grant_users_view(user) }

      it "returns 404 error" do
        get "/api/v1/users/#{SecureRandom.uuid}", headers: { "Authorization" => "Bearer #{auth_token}" }

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "when the requested user is soft deleted" do
      let(:requester) { create(:user) }
      let(:auth_token) { JsonWebToken.encode(user_id: requester.id) }

      before do
        grant_users_view(requester)
        user.soft_delete
      end

      it "returns 404 error" do
        get "/api/v1/users/#{user.id}", headers: { "Authorization" => "Bearer #{auth_token}" }

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "when the authenticated user has been soft deleted" do
      before { user.soft_delete }

      it "returns 401 unauthorized since a deleted user can no longer authenticate" do
        get "/api/v1/users/#{user.id}", headers: { "Authorization" => "Bearer #{auth_token}" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
