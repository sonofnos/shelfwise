class PaymentWebhooksController < ApplicationController
  skip_before_action :authenticate_request!

  # Payment processors retry webhooks on any ambiguous response (timeout,
  # 5xx), so the same event can arrive more than once. Idempotency here
  # rests on a unique DB constraint on event_id (ProcessedWebhookEvent) --
  # the insert itself is the lock, so two concurrent deliveries of the same
  # event can't both "win" and double-process it.
  def create
    unless valid_signature?
      render json: { error: "Invalid signature" }, status: :unauthorized
      return
    end

    event_id = payload["event_id"]
    order = Order.find_by(external_reference: payload["order_reference"])

    if order.nil?
      render json: { error: "Unknown order" }, status: :unprocessable_entity
      return
    end

    begin
      ProcessedWebhookEvent.create!(event_id: event_id, event_type: payload["type"])
    rescue ActiveRecord::RecordNotUnique
      render json: { status: "already processed" }, status: :ok
      return
    end

    order.mark_paid! if payload["type"] == "payment.succeeded" && order.pending?

    render json: { status: "ok" }, status: :ok
  end

  private

  def payload
    @payload ||= JSON.parse(request.raw_post)
  rescue JSON::ParserError
    {}
  end

  def valid_signature?
    signature = request.headers["X-Webhook-Signature"]
    return false if signature.blank?

    expected = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, request.raw_post)
    ActiveSupport::SecurityUtils.secure_compare(signature, expected)
  end

  def webhook_secret
    Rails.application.credentials.dig(:payment_webhook_secret) || ENV.fetch("PAYMENT_WEBHOOK_SECRET", "development-secret")
  end
end
