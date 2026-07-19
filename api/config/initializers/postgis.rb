# frozen_string_literal: true

Rails.application.config.generators do |g|
  g.test_framework :test_unit, fixture: false
end
