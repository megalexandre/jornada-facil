# frozen_string_literal: true

# RBAC catalog structure, mirrored in the Flutter app (app/lib/core/models/rbac.dart).
# Domain resources are the ones the client app has user-facing screens for;
# admin resources gate administration features. Both groups are serialized
# on login/me so the app can gate admin UI.
module Rbac
  ADMIN_RESOURCES = %w[users roles permissions notification weekly_review].freeze
  DOMAIN_RESOURCES = %w[journey history profile].freeze
  ALL_RESOURCES = (ADMIN_RESOURCES + DOMAIN_RESOURCES).freeze
  ACTIONS = %w[view create update delete].freeze

  # Serialized shorthand: "resource:*" = every action on the resource,
  # "*" = every action on every resource (domain + admin).
  WILDCARD = "*"
end
