# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users Inactivate", type: :request do
  describe "PATCH /api/v1/users/:id/inactivate" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }
    let(:employee) { create(:user) }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the users:delete permission" do
      before { grant("users", "delete") }

      it "soft-deletes the employee and returns 200 with active false" do
        patch "/api/v1/users/#{employee.id}/inactivate", headers: headers

        expect(response).to have_http_status(:ok)
        expect(User.exists?(employee.id)).to be(false) # hidden by the default scope
        expect(User.unscoped.find(employee.id)).to be_deleted
        expect(json_response).to include("id" => employee.id.to_s, "active" => false)
      end

      it "returns 404 when the employee is already inactive" do
        employee.soft_delete

        patch "/api/v1/users/#{employee.id}/inactivate", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "without the users:delete permission" do
      it "returns 403 forbidden" do
        patch "/api/v1/users/#{employee.id}/inactivate", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        patch "/api/v1/users/#{employee.id}/inactivate"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
