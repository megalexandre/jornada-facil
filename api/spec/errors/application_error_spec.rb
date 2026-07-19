# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationError do
  it "defaults to a 500 status when a subclass doesn't override it" do
    expect(described_class.new.status).to eq(:internal_server_error)
  end
end
