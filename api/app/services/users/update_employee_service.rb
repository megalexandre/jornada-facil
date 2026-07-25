# frozen_string_literal: true

module Users
  # Updates an employee's editable fields. A blank password is dropped so an
  # edit without a password change keeps the current one.
  class UpdateEmployeeService
    def self.call(actor:, id:, attributes:)
      new(actor:, id:, attributes:).call
    end

    def initialize(actor:, id:, attributes:)
      @actor = actor
      @id = id
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      user = GetUserService.call(id: @id)

      attributes = @attributes.merge(updated_by: @actor.id)
      attributes.delete(:password) if attributes[:password].blank?

      raise InvalidParameters, user.errors unless user.update(attributes)

      user
    end
  end
end
