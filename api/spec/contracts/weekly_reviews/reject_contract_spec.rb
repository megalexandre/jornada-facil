# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReviews::RejectContract do
  describe ".validate!" do
    it "accepts a comment with an optional week_start" do
      contract = described_class.validate!(comment: "Faltas sem justificativa", week_start: "2026-07-06")

      expect(contract.comment).to eq("Faltas sem justificativa")
      expect(contract.week_start).to eq("2026-07-06")
    end

    it "requires a comment" do
      expect { described_class.validate!(week_start: "2026-07-06") }
        .to raise_error(InvalidParameters, /Comment can't be blank/)
    end

    it "still validates the week_start format" do
      expect { described_class.validate!(comment: "ok", week_start: "nope") }
        .to raise_error(InvalidParameters, /Week start must be a valid date/)
    end
  end
end
