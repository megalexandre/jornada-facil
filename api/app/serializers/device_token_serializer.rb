# frozen_string_literal: true

class DeviceTokenSerializer
  def initialize(device_token)
    @device_token = device_token
  end

  def as_json
    {
      id: @device_token.id,
      token: @device_token.token,
      platform: @device_token.platform
    }
  end
end
