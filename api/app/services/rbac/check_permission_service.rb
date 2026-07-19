# frozen_string_literal: true

module Rbac
  # Answers "can this user do resource:action?" with a fresh DB check, so a
  # revoked role takes effect immediately instead of waiting for JWT expiry.
  class CheckPermissionService
    def self.call(user:, permission:)
      new(user:, permission:).call
    end

    def initialize(user:, permission:)
      @user = user
      @permission = permission
    end

    def call
      resource, action = @permission.to_s.split(":", 2)
      @user.roles.joins(:permissions).exists?(permissions: { resource: resource, action: action })
    end
  end
end
