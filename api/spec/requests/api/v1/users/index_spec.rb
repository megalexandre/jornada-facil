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
        expect(json_response).to eq([
          { "id" => ana.id.to_s, "name" => "Ana" },
          { "id" => bruno.id.to_s, "name" => "Bruno" },
          { "id" => user.id.to_s, "name" => "Carla" }
        ])
      end

      it "excludes soft-deleted users" do
        deleted = create(:user, name: "Deletado")
        deleted.soft_delete

        get "/api/v1/users", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response.map { |u| u["id"] }).to eq([ user.id.to_s ])
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
end
