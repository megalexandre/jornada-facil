# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users::WeeklyReviews Approve", type: :request do
  describe "POST /api/v1/users/:user_id/weekly_review/approve" do
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

      it "approves the week and returns the review" do
        post "/api/v1/users/#{target.id}/weekly_review/approve",
             params: { week_start: "2026-06-01" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response["status"]).to eq("approved")
        expect(json_response["comment"]).to be_nil
        expect(json_response["week_start"]).to eq("2026-06-01")
        expect(json_response["reviewer_name"]).to eq("Admin")
        expect(json_response["reviewed_at"]).to be_present

        review = WeeklyReview.find_by(user: target, week_start: Date.new(2026, 6, 1))
        expect(review).to be_approved
        expect(review.reviewer).to eq(user)
      end

      it "overwrites a previous rejection" do
        create(:weekly_review, :rejected, user: target, week_start: Date.new(2026, 6, 1))

        post "/api/v1/users/#{target.id}/weekly_review/approve",
             params: { week_start: "2026-06-01" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response["status"]).to eq("approved")
        expect(WeeklyReview.where(user: target).count).to eq(1)
      end

      it "returns 404 when the target user does not exist" do
        post "/api/v1/users/#{SecureRandom.uuid}/weekly_review/approve",
             params: { week_start: "2026-06-01" }, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "with only the weekly_review:view permission" do
      before { grant("weekly_review", "view") }

      it "returns 403 forbidden" do
        post "/api/v1/users/#{target.id}/weekly_review/approve", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        post "/api/v1/users/#{target.id}/weekly_review/approve"

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
