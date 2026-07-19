# frozen_string_literal: true

class JsonWebToken
  ALGORITHM = "HS256".freeze

  def self.encode(payload, exp = 24.hours.from_now)
    payload = payload.merge(exp: exp.to_i)
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    return nil if token.blank?

    decoded = JWT.decode(token, secret, true, algorithm: ALGORITHM).first
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError
    nil
  end

  def self.secret
    Rails.application.secret_key_base
  end
  private_class_method :secret
end
