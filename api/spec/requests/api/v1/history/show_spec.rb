# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::History Show", type: :request do
  describe "GET /api/v1/history" do
    let(:user) { create(:user) }
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

    context "with the history:view permission" do
      before { grant("history", "view") }

      it "returns the current user's own week with totals and 7 days" do
        create(:journey, user: user,
                         started_at: local(2026, 6, 1, 8, 0),
                         finished_at: local(2026, 6, 1, 12, 0))
        create(:journey, user: user,
                         started_at: local(2026, 6, 1, 13, 0),
                         finished_at: local(2026, 6, 1, 17, 0))
        # Jornada de outro usuário na mesma semana não deve entrar na conta.
        create(:journey, user: create(:user),
                         started_at: local(2026, 6, 1, 8, 0),
                         finished_at: local(2026, 6, 1, 18, 0))

        get "/api/v1/history", params: { week_start: "2026-06-01" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response["user"]).to eq("id" => user.id, "name" => user.name)
        expect(json_response["week_start"]).to eq("2026-06-01")
        expect(json_response["week_end"]).to eq("2026-06-07")
        expect(json_response["total_minutes"]).to eq(480)
        expect(json_response["expected_minutes"]).to eq(2400)
        expect(json_response["days"].size).to eq(7)

        monday = json_response["days"].first
        expect(monday["date"]).to eq("2026-06-01")
        expect(monday["worked_minutes"]).to eq(480)
      end

      it "defaults to the current week when week_start is omitted" do
        get "/api/v1/history", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response["week_start"]).to eq(WeeklyReviews.normalize_week_start(nil).iso8601)
        expect(json_response["days"].size).to eq(7)
      end

      it "returns 422 for a malformed week_start" do
        get "/api/v1/history", params: { week_start: "nope" }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response["error"]).to match(/Week start/)
      end
    end

    context "with only the journey:view permission" do
      before { grant("journey", "view") }

      it "returns 403 forbidden" do
        get "/api/v1/history", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        get "/api/v1/history"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
