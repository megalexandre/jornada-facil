# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users Update", type: :request do
  describe "PATCH /api/v1/users/:id" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }
    let(:employee) do
      create(:user, name: "Antigo", username: "antigo", email: "antigo@example.com")
    end

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    let(:base_params) { { name: "Antigo", username: "antigo", email: "antigo@example.com" } }

    context "with the users:update permission" do
      before { grant("users", "update") }

      it "updates the editable fields and returns 200" do
        patch "/api/v1/users/#{employee.id}",
              params: base_params.merge(name: "Novo Nome"), headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(employee.reload.name).to eq("Novo Nome")
        expect(json_response).to include("id" => employee.id.to_s, "name" => "Novo Nome")
      end

      it "keeps the current password when the password is blank" do
        original_digest = employee.password_digest

        patch "/api/v1/users/#{employee.id}",
              params: base_params.merge(password: ""), headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(employee.reload.password_digest).to eq(original_digest)
      end

      it "changes the password when one is provided" do
        patch "/api/v1/users/#{employee.id}",
              params: base_params.merge(password: "BrandNew123"), headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(employee.reload.authenticate("BrandNew123")).to be_truthy
      end

      it "returns 422 when the name is blank" do
        patch "/api/v1/users/#{employee.id}",
              params: base_params.merge(name: ""), headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Name can't be blank")
        expect(employee.reload.name).to eq("Antigo")
      end

      it "returns 422 when the username is already taken" do
        create(:user, username: "tomado")

        patch "/api/v1/users/#{employee.id}",
              params: base_params.merge(username: "tomado"), headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Username has already been taken")
        expect(employee.reload.username).to eq("antigo")
      end

      it "returns 404 when the employee does not exist" do
        patch "/api/v1/users/#{SecureRandom.uuid}", params: base_params, headers: headers, as: :json

        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq("error" => "User not found")
      end
    end

    context "without the users:update permission" do
      it "returns 403 forbidden" do
        patch "/api/v1/users/#{employee.id}", params: base_params, headers: headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        patch "/api/v1/users/#{employee.id}", params: base_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
