# frozen_string_literal: true

module Rbac
  # Client-facing permission list for the login/me payload: every catalog
  # resource (domain + admin), folded with wildcards ("journey:*", or just
  # ["*"] when the user covers the whole catalog). This list is a UX hint for
  # the app — enforcement always goes through CheckPermissionService against
  # the full catalog in the DB.
  class GetPermissionsService
    def self.call(user:)
      new(user:).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      return [ WILDCARD ] if full_resources.to_set == ALL_RESOURCES.to_set

      actions_by_resource.flat_map do |resource, actions|
        if full_resources.include?(resource)
          "#{resource}:#{WILDCARD}"
        else
          actions.map { |action| "#{resource}:#{action}" }
        end
      end.sort
    end

    private

    def actions_by_resource
      @actions_by_resource ||= Permission
        .joins(:role_permissions)
        .where(role_permissions: { role_id: @user.role_ids }, resource: ALL_RESOURCES)
        .distinct
        .pluck(:resource, :action)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }
    end

    def full_resources
      @full_resources ||= actions_by_resource.select { |_, actions| (ACTIONS - actions).empty? }.keys
    end
  end
end
