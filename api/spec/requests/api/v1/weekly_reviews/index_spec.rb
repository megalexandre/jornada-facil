# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::WeeklyReviews Index", type: :request do
  describe "GET /api/v1/weekly_reviews" do
    let(:user) { create(:user, name: "Admin") }
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

      it "returns the week summary with one row per user" do
        ana = create(:user, name: "Ana")
        create(:journey, user: ana,
                         started_at: local(2026, 6, 1, 8, 0),
                         finished_at: local(2026, 6, 1, 18, 0))

        get "/api/v1/weekly_reviews", params: { week_start: "2026-06-01" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response["week_start"]).to eq("2026-06-01")
        expect(json_response["week_end"]).to eq("2026-06-07")
        expect(json_response).to have_key("compliance_rate")
        expect(json_response).to have_key("previous_compliance_rate")

        ana_row = json_response["users"].find { |row| row["id"] == ana.id }
        expect(ana_row).to eq(
          "id" => ana.id,
          "name" => "Ana",
          "status" => "alert",
          "worked_minutes" => 600,
          "expected_minutes" => 2400,
          "overtime_minutes" => 120,
          "absences" => 4,
        )
      end

      it "returns 422 for a malformed week_start" do
        get "/api/v1/weekly_reviews", params: { week_start: "nope" }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response["error"]).to match(/Week start/)
      end
    end

    context "with only the users:view permission" do
      before { grant("users", "view") }

      it "returns 403 forbidden" do
        get "/api/v1/weekly_reviews", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        get "/api/v1/weekly_reviews"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end

    context "with invalid token" do
      it "returns 401 unauthorized" do
        get "/api/v1/weekly_reviews", headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
