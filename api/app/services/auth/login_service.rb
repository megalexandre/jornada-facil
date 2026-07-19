# frozen_string_literal: true

module Auth
  class LoginService
    Result = Data.define(:user, :token, :expires_at)

    # Precomputed once so we can spend the same bcrypt time when the username
    # doesn't exist, preventing timing-based user enumeration.
    DUMMY_DIGEST = BCrypt::Password.create("timing_attack_mitigation")

    def self.call(username:, password:)
      new(username:, password:).call
    end

    def initialize(username:, password:)
      @username = username
      @password = password
    end

    def call
      user = User.find_by(username: @username)
      authenticated = user&.authenticate(@password)
      waste_time_on_bcrypt if user.nil?

      raise InvalidCredentials unless authenticated

      exp = 24.hours.from_now
      Result.new(
        user: user,
        token: JsonWebToken.encode({ user_id: user.id }, exp),
        expires_at: exp
      )
    end

    private

    # Run bcrypt against a throwaway digest so a missing user takes as long as
    # a wrong password, keeping login time independent of username existence.
    def waste_time_on_bcrypt
      BCrypt::Password.new(DUMMY_DIGEST).is_password?(@password)
    end
  end
end
