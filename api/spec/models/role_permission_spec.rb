# frozen_string_literal: true

require "rails_helper"

RSpec.describe RolePermission, type: :model do
  describe "validations" do
    let(:role) { create(:role) }
    let(:permission) { create(:permission) }

    before { create(:role_permission, role: role, permission: permission) }

    it "validates uniqueness of role_id scoped to permission_id" do
      duplicate = RolePermission.new(role_id: role.id, permission_id: permission.id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:role_id]).to include("has already been taken")
    end
  end
end
