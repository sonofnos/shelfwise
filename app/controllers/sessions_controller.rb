class SessionsController < ApplicationController
  skip_before_action :authenticate_request!, only: :create

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode({ user_id: user.id })
      render json: { token: token, user: user_json(user) }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  private

  def user_json(user)
    { id: user.id, name: user.name, email: user.email, role: user.role }
  end
end
