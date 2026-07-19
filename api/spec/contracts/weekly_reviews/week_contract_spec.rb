# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReviews::WeekContract do
  describe ".validate!" do
    it "accepts a valid ISO date" do
      contract = described_class.validate!(week_start: "2026-07-06")
      expect(contract.week_start).to eq("2026-07-06")
    end

    it "accepts a blank week_start (defaults to current week downstream)" do
      expect(described_class.validate!({}).week_start).to be_nil
    end

    it "raises InvalidParameters for a malformed date" do
      expect { described_class.validate!(week_start: "07/06/2026") }
        .to raise_error(InvalidParameters, /Week start must be a valid date/)
    end

    it "raises InvalidParameters for an impossible date" do
      expect { described_class.validate!(week_start: "2026-13-45") }
        .to raise_error(InvalidParameters, /Week start must be a valid date/)
    end
  end
end
