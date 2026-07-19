# frozen_string_literal: true

# Base for request/param contracts. A contract validates the *shape* of input
# at the boundary (presence, format, types) before it reaches a service, using
# plain ActiveModel validations. Invalid input raises InvalidParameters, which
# ErrorHandler renders centrally — controllers stay on the happy path.
#
# Subclasses declare their inputs with `attribute`; `from_params` uses those to
# strong-permit raw request params, so controllers never repeat the key list.
class ApplicationContract
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.from_params(params)
    validate!(params.permit(*attribute_names).to_h)
  end

  def self.validate!(attributes = {})
    new(attributes).tap do |contract|
      raise InvalidParameters, contract.errors unless contract.valid?
    end
  end
end
