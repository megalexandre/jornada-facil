# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::LoginContract do
  describe ".validate!" do
    it "returns the contract when username and password are present" do
      contract = described_class.validate!(username: "johndoe", password: "secret")

      expect(contract.username).to eq("johndoe")
      expect(contract.password).to eq("secret")
    end

    it "raises InvalidParameters when username is blank" do
      expect { described_class.validate!(password: "secret") }
        .to raise_error(InvalidParameters, /Username can't be blank/)
    end

    it "raises InvalidParameters when password is blank" do
      expect { described_class.validate!(username: "johndoe") }
        .to raise_error(InvalidParameters, /Password can't be blank/)
    end

    it "carries a 422 status and the field errors" do
      expect { described_class.validate!({}) }.to raise_error(InvalidParameters) do |error|
        expect(error.status).to eq(:unprocessable_content)
        expect(error.errors.full_messages)
          .to contain_exactly("Username can't be blank", "Password can't be blank")
      end
    end
  end

  describe ".from_params" do
    it "keeps only the declared attributes and drops anything else" do
      params = ActionController::Parameters.new(username: "johndoe", password: "secret", admin: true)

      contract = described_class.from_params(params)

      expect(contract.username).to eq("johndoe")
      expect(contract.password).to eq("secret")
      expect(contract).not_to respond_to(:admin)
    end

    it "raises InvalidParameters when a required param is missing" do
      params = ActionController::Parameters.new(username: "johndoe")

      expect { described_class.from_params(params) }
        .to raise_error(InvalidParameters, /Password can't be blank/)
    end
  end
end
