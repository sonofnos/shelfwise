module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
  end

  def current_user
    @current_user
  end

  private

  def authenticate_request!
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last

    if token.blank?
      render json: { error: "Missing authorization token" }, status: :unauthorized
      return
    end

    payload = JsonWebToken.decode(token)
    @current_user = User.find_by(id: payload[:user_id])

    render json: { error: "Invalid or expired token" }, status: :unauthorized if @current_user.nil?
  rescue JsonWebToken::DecodeError => e
    render json: { error: e.message }, status: :unauthorized
  end

  def authorize_roles!(*roles)
    return if roles.map(&:to_s).include?(current_user.role)

    render json: { error: "You are not authorized to perform this action" }, status: :forbidden
  end
end
