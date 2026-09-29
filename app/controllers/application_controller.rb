class ApplicationController < ActionController::API
  include Authenticatable

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from StockItem::InsufficientStockError, with: :render_conflict

  private

  def render_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def render_unprocessable(exception)
    render json: { error: exception.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def render_conflict(exception)
    render json: { error: exception.message }, status: :conflict
  end
end
