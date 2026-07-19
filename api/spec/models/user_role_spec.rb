# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserRole, type: :model do
  describe "validations" do
    let(:user) { create(:user) }
    let(:role) { create(:role) }

    before { create(:user_role, user: user, role: role) }

    it "validates uniqueness of user_id scoped to role_id" do
      duplicate = UserRole.new(user_id: user.id, role_id: role.id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end
  end
end
