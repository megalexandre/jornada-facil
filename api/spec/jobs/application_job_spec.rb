# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob do
  it "is an ActiveJob base for the app's jobs" do
    expect(described_class.superclass).to eq(ActiveJob::Base)
  end
end
