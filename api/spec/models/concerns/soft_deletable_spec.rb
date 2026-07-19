# frozen_string_literal: true

require "rails_helper"

RSpec.describe SoftDeletable, type: :model do
  # User inclui SoftDeletable; usamos ele como host concreto do concern.
  subject(:record) { create(:user) }

  describe "#deleted?" do
    it "is false while the record is alive" do
      expect(record.deleted?).to be(false)
    end

    it "is true after a soft delete" do
      record.soft_delete

      expect(record.deleted?).to be(true)
    end
  end
end
