# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Journeys Index", type: :request do
  describe "GET /api/v1/journeys" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the journey:view permission" do
      before { grant("journey", "view") }

      it "returns only the user's journeys, most recent first" do
        older = create(:journey, :finished, user: user)
        newer = create(:journey, user: user, started_at: 1.minute.ago)
        create(:journey) # another user's journey

        get "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response.map { |j| j["id"] }).to eq([ newer.id, older.id ])
      end

      it "returns an empty array when the user has no journeys" do
        get "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])
      end
    end

    context "without the journey:view permission" do
      it "returns 403 forbidden" do
        get "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        get "/api/v1/journeys"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
