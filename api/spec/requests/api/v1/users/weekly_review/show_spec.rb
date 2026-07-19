# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users::WeeklyReviews Show", type: :request do
  describe "GET /api/v1/users/:user_id/weekly_review" do
    let(:user) { create(:user) }
    let(:target) { create(:user, name: "Ana") }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    def local(*args)
      WeeklyReviews.time_zone.local(*args)
    end

    context "with the weekly_review:view permission" do
      before { grant("weekly_review", "view") }

      it "returns the user's week detail with 7 days and HH:MM intervals" do
        factory = Journeys::LocationContract::FACTORY
        create(:journey, user: target,
                         started_at: local(2026, 6, 1, 8, 0),
                         finished_at: local(2026, 6, 1, 12, 0),
                         started_location: factory.point(-46.633308, -23.55052),
                         finished_location: factory.point(-46.634000, -23.55100))
        create(:journey, user: target,
                         started_at: local(2026, 6, 1, 13, 0),
                         finished_at: local(2026, 6, 1, 17, 0))

        get "/api/v1/users/#{target.id}/weekly_review",
            params: { week_start: "2026-06-01" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response["user"]).to eq("id" => target.id, "name" => "Ana")
        expect(json_response["week_start"]).to eq("2026-06-01")
        expect(json_response["total_minutes"]).to eq(480)
        expect(json_response["standard_minutes"]).to eq(480)
        expect(json_response["overtime_minutes"]).to eq(0)
        expect(json_response["expected_minutes"]).to eq(2400)
        expect(json_response["absences"]).to eq(4)
        expect(json_response["review"]).to be_nil
        expect(json_response["days"].size).to eq(7)

        monday = json_response["days"].first
        expect(monday["date"]).to eq("2026-06-01")
        expect(monday["status"]).to eq("pending")
        expect(monday["intervals"]).to eq([
          {
            "start" => "08:00", "end" => "12:00",
            "start_location" => { "latitude" => -23.55052, "longitude" => -46.633308 },
            "end_location" => { "latitude" => -23.551, "longitude" => -46.634 }
          },
          {
            "start" => "13:00", "end" => "17:00",
            "start_location" => nil, "end_location" => nil
          }
        ])
      end

      it "includes the stored review" do
        create(:weekly_review, :rejected, user: target, week_start: Date.new(2026, 6, 1))

        get "/api/v1/users/#{target.id}/weekly_review",
            params: { week_start: "2026-06-01" }, headers: headers

        expect(json_response["review"]["status"]).to eq("rejected")
        expect(json_response["review"]["comment"]).to eq("Horas inconsistentes")
      end

      it "returns 404 when the target user does not exist" do
        get "/api/v1/users/#{SecureRandom.uuid}/weekly_review", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "with only the users:view permission" do
      before { grant("users", "view") }

      it "returns 403 forbidden" do
        get "/api/v1/users/#{target.id}/weekly_review", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/#{target.id}/weekly_review"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
