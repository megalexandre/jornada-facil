# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::DeviceTokens Create", type: :request do
  describe "POST /api/v1/device_tokens" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    context "with a valid token" do
      it "registers the device token and returns 200" do
        post "/api/v1/device_tokens", params: { token: "abc" }, headers: headers

        expect(response).to have_http_status(:ok)
        device_token = user.device_tokens.sole
        expect(device_token.platform).to eq("android")
        expect(json_response).to eq(
          "id" => device_token.id,
          "token" => "abc",
          "platform" => "android"
        )
      end

      it "is idempotent when re-registering the same token" do
        create(:device_token, user: user, token: "abc")

        post "/api/v1/device_tokens", params: { token: "abc" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(DeviceToken.count).to eq(1)
        expect(DeviceToken.sole.user).to eq(user)
      end

      it "re-links a token owned by another user" do
        other_user = create(:user)
        create(:device_token, user: other_user, token: "abc")

        post "/api/v1/device_tokens", params: { token: "abc" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(DeviceToken.count).to eq(1)
        expect(DeviceToken.sole.user).to eq(user)
      end

      it "accepts an explicit platform" do
        post "/api/v1/device_tokens", params: { token: "abc", platform: "ios" }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(user.device_tokens.sole.platform).to eq("ios")
      end
    end

    context "with invalid parameters" do
      it "returns 422 when the token is blank" do
        post "/api/v1/device_tokens", headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Token can't be blank")
      end

      it "returns 422 when the platform is unknown" do
        post "/api/v1/device_tokens", params: { token: "abc", platform: "windows" }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Platform is not included in the list")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        post "/api/v1/device_tokens", params: { token: "abc" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
