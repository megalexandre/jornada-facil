# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Journeys Create", type: :request do
  describe "POST /api/v1/journeys" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the journey:create permission" do
      before { grant("journey", "create") }

      it "opens a journey and returns 201" do
        post "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:created)
        journey = user.journeys.sole
        expect(json_response).to eq(
          "id" => journey.id,
          "started_at" => journey.started_at.iso8601,
          "finished_at" => nil,
          "started_location" => nil,
          "finished_location" => nil
        )
      end

      it "records where the user opened the journey when a location is sent" do
        post "/api/v1/journeys",
             params: { latitude: -23.55052, longitude: -46.633308 },
             headers: headers, as: :json

        expect(response).to have_http_status(:created)
        journey = user.journeys.sole
        expect(journey.started_location.y).to eq(-23.55052)
        expect(journey.started_location.x).to eq(-46.633308)
        expect(json_response["started_location"]).to eq(
          "latitude" => -23.55052,
          "longitude" => -46.633308
        )
      end

      it "returns 422 when the location is incomplete" do
        post "/api/v1/journeys",
             params: { latitude: -23.55052 },
             headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Longitude can't be blank")
        expect(user.journeys).to be_empty
      end

      it "returns 422 when the location is out of range" do
        post "/api/v1/journeys",
             params: { latitude: 91.0, longitude: -46.633308 },
             headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response["error"]).to include("Latitude")
        expect(user.journeys).to be_empty
      end

      it "returns 422 when a journey is already open" do
        create(:journey, user: user)

        post "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "There is already an open journey")
      end
    end

    context "without the journey:create permission" do
      it "returns 403 forbidden" do
        post "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "when the user does not track a journey" do
      let(:user) { create(:user, :no_journey) }

      before { grant("journey", "create") }

      it "returns 403 forbidden even with journey:create" do
        post "/api/v1/journeys", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Usuário não registra jornada")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        post "/api/v1/journeys"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
