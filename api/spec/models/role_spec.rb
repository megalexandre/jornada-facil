# frozen_string_literal: true

require "rails_helper"

RSpec.describe Role, type: :model do
  describe "validations" do
    it "validates presence of name" do
      role = Role.new(name: nil)
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("can't be blank")
    end

    it "validates uniqueness of name" do
      create(:role, name: "admin")
      role = Role.new(name: "admin")
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("has already been taken")
    end
  end
end
