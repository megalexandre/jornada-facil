# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::GetUserService do
  describe ".call" do
    context "when the user exists" do
      let!(:user) { create(:user) }

      it "returns the user" do
        expect(described_class.call(id: user.id)).to eq(user)
      end
    end

    shared_examples "not found" do
      it "raises RecordNotFound with a 404 status" do
        expect { call }.to raise_error(RecordNotFound) do |error|
          expect(error.message).to eq("User not found")
          expect(error.status).to eq(:not_found)
        end
      end
    end

    context "when no user matches the id" do
      let(:call) { described_class.call(id: SecureRandom.uuid) }
      include_examples "not found"
    end

    context "when the user is soft-deleted" do
      let!(:user) { create(:user) }
      before { user.soft_delete }

      let(:call) { described_class.call(id: user.id) }
      include_examples "not found"
    end
  end
end
