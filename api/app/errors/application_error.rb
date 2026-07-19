# frozen_string_literal: true

# Base class for domain errors that map to an HTTP response.
# Raise a subclass from anywhere (services, models, ...); ErrorHandler renders
# it centrally, so controllers only deal with the happy path.
class ApplicationError < StandardError
  def status
    :internal_server_error
  end
end
