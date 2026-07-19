# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rbac::CheckPermissionService do
  let(:user) { create(:user) }
  let(:role) { create(:role, name: "admin") }
  let(:permission) { create(:permission, resource: "users", action: "view") }

  context "when user has a role with the permission" do
    before do
      user.roles << role
      role.permissions << permission
    end

    it "returns true" do
      expect(described_class.call(user: user, permission: "users:view")).to be true
    end
  end

  context "when user does not have the permission" do
    before { user.roles << role }

    it "returns false" do
      expect(described_class.call(user: user, permission: "users:view")).to be false
    end
  end

  context "with a malformed token" do
    it "returns false" do
      expect(described_class.call(user: user, permission: "nonsense")).to be false
    end
  end
end
