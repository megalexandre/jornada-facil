# frozen_string_literal: true

module Users
  # Full employee shape for the admin management screens (create/update/inactivate/
  # restore/index/show). Separate from the minimal UserSerializer used where only
  # id/name is needed (e.g. the weekly review embed).
  class EmployeeSerializer
    def initialize(user)
      @user = user
    end

    def as_json
      {
        id: @user.id,
        name: @user.name,
        username: @user.username,
        email: @user.email,
        tracks_journey: @user.tracks_journey,
        active: @user.deleted_at.nil?
      }
    end
  end
end
