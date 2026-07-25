# frozen_string_literal: true

module Users
  # Inactivates an employee (soft delete). An already-inactive id is hidden by
  # the model's default scope, so it surfaces as RecordNotFound (404).
  class InactivateEmployeeService
    def self.call(actor:, id:)
      new(actor:, id:).call
    end

    def initialize(actor:, id:)
      @actor = actor
      @id = id
    end

    def call
      user = GetUserService.call(id: @id)
      user.soft_delete(@actor.id)
      user
    end
  end
end
