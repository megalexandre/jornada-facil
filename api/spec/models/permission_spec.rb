# frozen_string_literal: true

require "rails_helper"

RSpec.describe Permission, type: :model do
  describe "validations" do
    it "validates presence of resource and action" do
      permission = Permission.new(resource: nil, action: nil)
      expect(permission).not_to be_valid
      expect(permission.errors[:resource]).to include("can't be blank")
      expect(permission.errors[:action]).to include("can't be blank")
    end

    it "validates uniqueness of resource scoped to action" do
      create(:permission, resource: "users", action: "view")
      permission = Permission.new(resource: "users", action: "view")
      expect(permission).not_to be_valid
      expect(permission.errors[:resource]).to include("has already been taken")
    end
  end

  describe "#to_rbac" do
    it "returns the resource:action token" do
      permission = build(:permission, resource: "users", action: "view")
      expect(permission.to_rbac).to eq("users:view")
    end
  end
end
