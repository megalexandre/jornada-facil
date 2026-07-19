# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::SendPushService do
  let(:user) { create(:user) }

  it "sends the notification to every device of the user" do
    tokens = create_list(:device_token, 2, user: user)
    allow(Fcm::Client).to receive(:send_notification).and_return(true)

    result = described_class.call(user: user, title: "Aviso", body: "Olá")

    expect(result).to eq({ sent: 2 })
    tokens.each do |device_token|
      expect(Fcm::Client).to have_received(:send_notification).with(
        token: device_token.token, title: "Aviso", body: "Olá"
      )
    end
  end

  it "removes stale tokens and keeps sending to the others" do
    stale = create(:device_token, user: user)
    alive = create(:device_token, user: user)
    allow(Fcm::Client).to receive(:send_notification).and_return(true)
    allow(Fcm::Client).to receive(:send_notification)
      .with(hash_including(token: stale.token))
      .and_raise(Fcm::Client::StaleToken)

    result = described_class.call(user: user, title: "Aviso", body: "Olá")

    expect(result).to eq({ sent: 1 })
    expect(DeviceToken.exists?(stale.id)).to be(false)
    expect(DeviceToken.exists?(alive.id)).to be(true)
  end

  it "returns zero when the user has no registered devices" do
    allow(Fcm::Client).to receive(:send_notification)

    result = described_class.call(user: user, title: "Aviso", body: "Olá")

    expect(result).to eq({ sent: 0 })
    expect(Fcm::Client).not_to have_received(:send_notification)
  end
end
