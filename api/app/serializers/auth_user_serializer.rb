# frozen_string_literal: true

class AuthUserSerializer
  def initialize(user)
    @user = user
  end

  def as_json
    {
      id: @user.id,
      username: @user.username,
      name: @user.name,
      email: @user.email,
      tracks_journey: @user.tracks_journey,
      permissions: Rbac::GetPermissionsService.call(user: @user),
      imageBase64: nil
    }
  end
end
