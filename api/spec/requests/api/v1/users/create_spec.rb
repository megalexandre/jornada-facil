# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users Create", type: :request do
  describe "POST /api/v1/users" do
    let(:user) { create(:user) }
    let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    def grant(resource, action)
      role = create(:role)
      role.permissions << create(:permission, resource: resource, action: action)
      user.roles << role
    end

    let(:valid_params) do
      { name: "Novo Funcionario", username: "novo.func", email: "novo@example.com", password: "Password123!" }
    end

    context "with the users:create permission" do
      before do
        grant("users", "create")
        create(:role, name: "user") # domain role attached to the new employee
      end

      it "creates a journey-tracking employee and returns 201" do
        expect do
          post "/api/v1/users", params: valid_params, headers: headers, as: :json
        end.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        created = User.find_by(username: "novo.func")
        expect(created.tracks_journey).to be(true)
        expect(created.roles.map(&:name)).to include("user")
        expect(json_response).to eq(
          "id" => created.id.to_s,
          "name" => "Novo Funcionario",
          "username" => "novo.func",
          "email" => "novo@example.com",
          "tracks_journey" => true,
          "active" => true
        )
      end

      it "returns 422 when the name is missing" do
        post "/api/v1/users", params: valid_params.except(:name), headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Name can't be blank")
        expect(User.find_by(username: "novo.func")).to be_nil
      end

      it "returns 422 when the username is already taken" do
        create(:user, username: "novo.func")

        post "/api/v1/users", params: valid_params, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Username has already been taken")
      end

      it "returns 422 when the password is too short" do
        post "/api/v1/users", params: valid_params.merge(password: "123"), headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response).to eq("error" => "Password is too short (minimum is 6 characters)")
      end
    end

    context "without the users:create permission" do
      it "returns 403 forbidden" do
        post "/api/v1/users", params: valid_params, headers: headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(json_response).to eq("error" => "Forbidden")
      end
    end

    context "without authentication token" do
      it "returns 401 unauthorized" do
        post "/api/v1/users", params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to eq("error" => "Unauthorized")
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
