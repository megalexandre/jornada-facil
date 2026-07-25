# frozen_string_literal: true

module Users
  # Creates an employee: a user who tracks journeys (`tracks_journey: true`),
  # holding the domain "user" role. Model validation failures surface as
  # InvalidParameters (422) with readable messages.
  class CreateEmployeeService
    EMPLOYEE_ROLE = "user"

    def self.call(actor:, attributes:)
      new(actor:, attributes:).call
    end

    def initialize(actor:, attributes:)
      @actor = actor
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      user = User.new(
        @attributes.merge(tracks_journey: true, created_by: @actor.id)
      )
      raise InvalidParameters, user.errors unless user.save

      user.roles << employee_role
      user
    end

    private

    def employee_role
      @employee_role ||= Role.find_by!(name: EMPLOYEE_ROLE)
    end
  end
end
