# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users::Journeys Index", type: :request do
  describe "GET /api/v1/users/:user_id/journeys" do
    let(:user) { create(:user) }
    let(:target) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the users:view permission" do
      before { grant("users", "view") }

      it "returns only the target user's journeys, most recent first" do
        older = create(:journey, :finished, user: target)
        newer = create(:journey, user: target, started_at: 1.minute.ago)
        create(:journey) # another user's journey

        get "/api/v1/users/#{target.id}/journeys", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response.map { |j| j["id"] }).to eq([ newer.id, older.id ])
        expect(json_response.first).to eq(
          "id" => newer.id,
          "started_at" => newer.started_at.iso8601,
          "finished_at" => nil,
          "started_location" => nil,
          "finished_location" => nil,
        )
        expect(json_response.last["finished_at"]).to eq(older.finished_at.iso8601)
      end

      it "returns an empty array when the target user has no journeys" do
        get "/api/v1/users/#{target.id}/journeys", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])
      end

      it "returns 404 when the target user does not exist" do
        get "/api/v1/users/#{SecureRandom.uuid}/journeys", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end

      it "returns 404 when the target user is soft deleted" do
        target.soft_delete

        get "/api/v1/users/#{target.id}/journeys", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "with only the journey:view permission" do
      before { grant("journey", "view") }

      it "returns 403 forbidden (self-service permission is not enough)" do
        get "/api/v1/users/#{target.id}/journeys", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/#{target.id}/journeys"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end

    context "with invalid token" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/#{target.id}/journeys", headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
