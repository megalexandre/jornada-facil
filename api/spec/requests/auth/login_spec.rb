# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth Login", type: :request do
  describe "POST /api/v1/auth/login" do
    context "with valid credentials" do
      let(:user) { create(:user, username: "johndoe", password: "Password123!") }
      let(:admin_role) { create(:role, name: "admin") }
      let(:delete_permission) { create(:permission, resource: "journey", action: "delete") }
      let(:create_permission) { create(:permission, resource: "journey", action: "create") }

      before do
        user
        admin_role.permissions << [ delete_permission, create_permission ]
        user.roles << admin_role
      end

      it "returns 200 with token, expiration and the user with flat resource:action permissions" do
        post "/api/v1/auth/login", params: {
          username: user.username,
          password: "Password123!"
        }

        expect(response).to have_http_status(:ok)
        expect(json_response).to include("token" => be_a(String), "expires_at" => be_a(String))
        expect(json_response.keys).to match_array(%w[token expires_at user])
        expect(json_response["user"]).to eq(
          "id" => user.id,
          "username" => "johndoe",
          "name" => user.name,
          "email" => user.email,
          "tracks_journey" => true,
          "permissions" => [ "journey:create", "journey:delete" ],
          "imageBase64" => nil
        )
      end
    end

    context "with invalid password" do
      let(:user) { create(:user, username: "johndoe", password: "Password123!") }

      before { user }

      it "returns 401 error" do
        post "/api/v1/auth/login", params: {
          username: user.username,
          password: "WrongPassword"
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Invalid username or password")
      end
    end

    context "with non-existent username" do
      it "returns 401 error" do
        post "/api/v1/auth/login", params: {
          username: "nobody",
          password: "Password123!"
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Invalid username or password")
      end
    end

    context "with missing parameters" do
      it "returns 422 when password is missing" do
        post "/api/v1/auth/login", params: { username: "johndoe" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Password can't be blank")
      end

      it "returns 422 listing every missing field" do
        post "/api/v1/auth/login", params: {}

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Username can't be blank and Password can't be blank")
      end
    end

    context "when user is soft deleted" do
      let(:user) { create(:user, username: "johndoe", password: "Password123!") }

      before do
        user
        user.soft_delete
      end

      it "returns 401 error" do
        post "/api/v1/auth/login", params: {
          username: user.username,
          password: "Password123!"
        }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Invalid username or password")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
