# frozen_string_literal: true

module Users
  # Reactivates a previously inactivated employee. Looks up via `unscoped` since
  # the default scope hides soft-deleted rows.
  class RestoreEmployeeService
    def self.call(actor:, id:)
      new(actor:, id:).call
    end

    def initialize(actor:, id:)
      @actor = actor
      @id = id
    end

    def call
      user = User.unscoped.find_by(id: @id) || raise(RecordNotFound.new("User"))
      user.update(deleted_at: nil, updated_by: @actor.id)
      user
    end
  end
end
