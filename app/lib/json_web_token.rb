class JsonWebToken
  ALGORITHM = "HS256".freeze

  class DecodeError < StandardError; end

  def self.encode(payload, exp: 24.hours.from_now)
    payload = payload.merge(exp: exp.to_i)
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    body = JWT.decode(token, secret, true, algorithm: ALGORITHM).first
    ActiveSupport::HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    raise DecodeError, "Invalid or expired token"
  end

  def self.secret
    Rails.application.secret_key_base
  end
end
