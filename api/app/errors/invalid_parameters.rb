# frozen_string_literal: true

# Raised when request parameters fail a contract's validation. Carries the
# ActiveModel::Errors so ErrorHandler can surface a readable message.
class InvalidParameters < ApplicationError
  attr_reader :errors

  def initialize(errors)
    @errors = errors
    super(errors.full_messages.to_sentence)
  end

  def status
    :unprocessable_content
  end
end
