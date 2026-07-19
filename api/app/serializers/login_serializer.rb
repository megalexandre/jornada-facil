# frozen_string_literal: true

class LoginSerializer
  def initialize(result)
    @result = result
  end

  def as_json
    {
      token: @result.token,
      expires_at: @result.expires_at.iso8601,
      user: AuthUserSerializer.new(@result.user).as_json
    }
  end
end
