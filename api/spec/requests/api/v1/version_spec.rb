# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Version", type: :request do
  describe "GET /api/v1/version" do
    it "returns 200 with version fields without auth" do
      get "/api/v1/version"

      expect(response).to have_http_status(:ok)
      expect(json_response.keys).to match_array(%w[version build_time])
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
