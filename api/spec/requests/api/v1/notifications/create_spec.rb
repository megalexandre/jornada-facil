# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Notifications Create", type: :request do
  describe "POST /api/v1/notifications" do
    let(:user) { create(:user) }
    let(:target_user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }
    let(:valid_params) { { user_id: target_user.id, title: "Aviso", body: "Sua jornada foi aprovada" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    context "with the notification:create permission" do
      before { grant("notification", "create") }

      it "sends the push to the target user's devices and returns 200" do
        allow(Notifications::SendPushService).to receive(:call).and_return({ sent: 2 })

        post "/api/v1/notifications", params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq("sent" => 2)
        expect(Notifications::SendPushService).to have_received(:call).with(
          user: target_user, title: "Aviso", body: "Sua jornada foi aprovada"
        )
      end

      it "returns 404 when the target user does not exist" do
        post "/api/v1/notifications",
          params: valid_params.merge(user_id: SecureRandom.uuid),
          headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end

      it "returns 422 when the title is missing" do
        post "/api/v1/notifications",
          params: valid_params.except(:title),
          headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Title can't be blank")
      end
    end

    context "without the notification:create permission" do
      it "returns 403 forbidden" do
        post "/api/v1/notifications", params: valid_params, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        post "/api/v1/notifications", params: valid_params

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
