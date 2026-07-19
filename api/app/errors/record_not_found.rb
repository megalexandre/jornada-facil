# frozen_string_literal: true

# Raised when a lookup finds no matching record. ErrorHandler renders it as 404,
# so services can fail loudly and controllers stay on the happy path.
class RecordNotFound < ApplicationError
  def initialize(resource = "Record")
    super("#{resource} not found")
  end

  def status
    :not_found
  end
end
