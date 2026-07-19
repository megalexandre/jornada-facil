# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeviceTokens::RegisterService do
  let(:user) { create(:user) }

  it "registers a new device token for the user" do
    device_token = described_class.call(user: user, token: "fcm-abc", platform: "android")

    expect(device_token).to be_persisted
    expect(device_token.user).to eq(user)
    expect(device_token.token).to eq("fcm-abc")
    expect(device_token.platform).to eq("android")
  end

  it "re-links an existing token to the last logged-in user" do
    other = create(:user)
    existing = create(:device_token, user: other, token: "fcm-shared")

    device_token = described_class.call(user: user, token: "fcm-shared")

    expect(device_token.id).to eq(existing.id)
    expect(device_token.user).to eq(user)
  end

  it "raises InvalidParameters when the token is invalid" do
    expect do
      described_class.call(user: user, token: "", platform: "android")
    end.to raise_error(InvalidParameters)
  end

  it "retries on a unique-index race and re-links the found record" do
    device_token = build(:device_token, user: user, token: "fcm-race")
    allow(DeviceToken).to receive(:find_or_initialize_by)
      .with(token: "fcm-race")
      .and_return(device_token)

    # 1º save perde a corrida contra o índice único; 2º save (na retentativa) vence.
    saves = [ -> { raise ActiveRecord::RecordNotUnique }, -> { true } ]
    allow(device_token).to receive(:save) { saves.shift.call }

    expect(described_class.call(user: user, token: "fcm-race")).to eq(device_token)
    expect(device_token).to have_received(:save).twice
  end
end
