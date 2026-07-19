# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users::WeeklyReviews Reject", type: :request do
  describe "POST /api/v1/users/:user_id/weekly_review/reject" do
    let(:user) { create(:user, name: "Admin") }
    let(:target) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the weekly_review:update permission" do
      before { grant("weekly_review", "update") }

      it "rejects the week with the comment and returns the review" do
        post "/api/v1/users/#{target.id}/weekly_review/reject",
             params: { week_start: "2026-06-01", comment: "Faltas sem justificativa" },
             headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response["status"]).to eq("rejected")
        expect(json_response["comment"]).to eq("Faltas sem justificativa")
        expect(json_response["reviewer_name"]).to eq("Admin")

        review = WeeklyReview.find_by(user: target, week_start: Date.new(2026, 6, 1))
        expect(review).to be_rejected
      end

      it "returns 422 without a comment" do
        post "/api/v1/users/#{target.id}/weekly_review/reject",
             params: { week_start: "2026-06-01" }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response["error"]).to match(/Comment/)
        expect(WeeklyReview.count).to eq(0)
      end

      it "returns 404 when the target user does not exist" do
        post "/api/v1/users/#{SecureRandom.uuid}/weekly_review/reject",
             params: { week_start: "2026-06-01", comment: "x" }, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "with only the weekly_review:view permission" do
      before { grant("weekly_review", "view") }

      it "returns 403 forbidden" do
        post "/api/v1/users/#{target.id}/weekly_review/reject",
             params: { comment: "x" }, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        post "/api/v1/users/#{target.id}/weekly_review/reject"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
