# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Journeys Finish", type: :request do
  describe "PATCH /api/v1/journeys/:id/finish" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the journey:update permission" do
      before { grant("journey", "update") }

      it "finishes the open journey and returns 200" do
        journey = create(:journey, user: user, started_at: 1.hour.ago)

        patch "/api/v1/journeys/#{journey.id}/finish", headers: headers

        expect(response).to have_http_status(:ok)
        journey.reload
        expect(journey.finished_at).to be_present
        expect(json_response).to eq(
          "id" => journey.id,
          "started_at" => journey.started_at.iso8601,
          "finished_at" => journey.finished_at.iso8601,
          "started_location" => nil,
          "finished_location" => nil
        )
      end

      it "records where the user finished the journey when a location is sent" do
        journey = create(:journey, user: user, started_at: 1.hour.ago)

        patch "/api/v1/journeys/#{journey.id}/finish",
              params: { latitude: -23.55052, longitude: -46.633308 },
              headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        journey.reload
        expect(journey.finished_location.y).to eq(-23.55052)
        expect(journey.finished_location.x).to eq(-46.633308)
        expect(json_response["finished_location"]).to eq(
          "latitude" => -23.55052,
          "longitude" => -46.633308
        )
      end

      it "returns 422 when the location is incomplete" do
        journey = create(:journey, user: user, started_at: 1.hour.ago)

        patch "/api/v1/journeys/#{journey.id}/finish",
              params: { longitude: -46.633308 },
              headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Latitude can't be blank")
        expect(journey.reload.finished_at).to be_nil
      end

      it "returns 404 for another user's journey" do
        journey = create(:journey)

        patch "/api/v1/journeys/#{journey.id}/finish", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "Journey not found")
      end

      it "returns 422 when the journey is already finished" do
        journey = create(:journey, :finished, user: user)

        patch "/api/v1/journeys/#{journey.id}/finish", headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Journey already finished")
      end
    end

    context "without the journey:update permission" do
      it "returns 403 forbidden" do
        journey = create(:journey, user: user)

        patch "/api/v1/journeys/#{journey.id}/finish", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        patch "/api/v1/journeys/#{SecureRandom.uuid}/finish"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
