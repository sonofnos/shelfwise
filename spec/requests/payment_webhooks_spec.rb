require "rails_helper"

RSpec.describe "Payment webhooks", type: :request do
  let(:warehouse) { create(:warehouse) }
  let(:product) { create(:product) }
  let!(:order) do
    create(:stock_item, product: product, warehouse: warehouse, quantity_on_hand: 10)
    Order.place!(customer_name: "Ada", customer_email: "ada@example.com", external_reference: "wh-ref-1",
                  items: [ { product: product, warehouse: warehouse, quantity: 2 } ])
  end

  def signed_post(body)
    raw = body.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", "development-secret", raw)
    post "/webhooks/payments", params: raw, headers: { "X-Webhook-Signature" => signature, "Content-Type" => "application/json" }
  end

  it "marks the order paid on a valid payment.succeeded event" do
    signed_post(event_id: "evt-1", type: "payment.succeeded", order_reference: order.external_reference)

    expect(response).to have_http_status(:ok)
    expect(order.reload).to be_paid
  end

  it "processes a replayed event only once" do
    signed_post(event_id: "evt-2", type: "payment.succeeded", order_reference: order.external_reference)
    order.reload.update!(status: :pending) # our in-memory copy is stale: the controller updated a separate instance

    signed_post(event_id: "evt-2", type: "payment.succeeded", order_reference: order.external_reference)

    expect(response).to have_http_status(:ok)
    expect(order.reload).to be_pending # second delivery was a no-op, not reprocessed
    expect(ProcessedWebhookEvent.where(event_id: "evt-2").count).to eq(1)
  end

  it "rejects a request with a bad signature" do
    post "/webhooks/payments",
      params: { event_id: "evt-3", type: "payment.succeeded", order_reference: order.external_reference }.to_json,
      headers: { "X-Webhook-Signature" => "wrong", "Content-Type" => "application/json" }

    expect(response).to have_http_status(:unauthorized)
    expect(order.reload).to be_pending
  end
end
