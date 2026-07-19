# frozen_string_literal: true

# Permission checks for controller actions, called inline from the action:
#   verify "users:view"
# Raising (instead of rendering) halts the action on the spot and lets
# ErrorHandler translate the error into the 403 response.
module Authorizable
  def verify(permission)
    authorized = current_user && ::Rbac::CheckPermissionService.call(user: current_user, permission: permission)
    raise Auth::Forbidden unless authorized
  end
end
