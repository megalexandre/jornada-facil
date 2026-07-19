# frozen_string_literal: true

# Central translation of domain errors into HTTP responses. Any ApplicationError
# raised during an action is rendered here, keeping controllers on the happy path.
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ApplicationError, with: :render_application_error
  end

  private

  def render_application_error(error)
    render json: { error: error.message }, status: error.status
  end
end
