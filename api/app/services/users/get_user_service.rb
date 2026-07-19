# frozen_string_literal: true

module Users
  # Fetches a single user by id. Soft-deleted users are excluded by the model's
  # default scope, so a deleted (or unknown) id surfaces as RecordNotFound.
  class GetUserService
    def self.call(id:)
      new(id:).call
    end

    def initialize(id:)
      @id = id
    end

    def call
      User.find_by(id: @id) || raise(RecordNotFound.new("User"))
    end
  end
end
