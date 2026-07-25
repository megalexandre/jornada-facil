# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users Restore", type: :request do
  describe "PATCH /api/v1/users/:id/restore" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }
    let(:employee) { create(:user).tap(&:soft_delete) }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the users:delete permission" do
      before { grant("users", "delete") }

      it "reactivates the employee and returns 200 with active true" do
        patch "/api/v1/users/#{employee.id}/restore", headers: headers

        expect(response).to have_http_status(:ok)
        expect(User.exists?(employee.id)).to be(true)
        expect(json_response).to include("id" => employee.id.to_s, "active" => true)
      end

      it "returns 404 when the id is unknown" do
        patch "/api/v1/users/#{SecureRandom.uuid}/restore", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "without the users:delete permission" do
      it "returns 403 forbidden" do
        patch "/api/v1/users/#{employee.id}/restore", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        patch "/api/v1/users/#{employee.id}/restore"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
