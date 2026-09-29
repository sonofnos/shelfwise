require "rails_helper"

RSpec.describe "Orders", type: :request do
  let(:staff) { create(:user, :admin) }
  let(:warehouse) { create(:warehouse) }
  let(:product) { create(:product) }

  before { create(:stock_item, product: product, warehouse: warehouse, quantity_on_hand: 10) }

  describe "POST /api/v1/orders" do
    it "places an order for an authorized user" do
      post "/api/v1/orders",
        params: {
          customer_name: "Ada",
          customer_email: "ada@example.com",
          external_reference: "req-ref-1",
          items: [ { product_id: product.id, warehouse_id: warehouse.id, quantity: 2 } ]
        },
        headers: staff_headers,
        as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["status"]).to eq("pending")
    end

    it "returns 409 when stock is insufficient" do
      post "/api/v1/orders",
        params: {
          customer_name: "Ada",
          customer_email: "ada@example.com",
          external_reference: "req-ref-2",
          items: [ { product_id: product.id, warehouse_id: warehouse.id, quantity: 999 } ]
        },
        headers: staff_headers,
        as: :json

      expect(response).to have_http_status(:conflict)
    end

    it "returns 401 without a token" do
      post "/api/v1/orders", params: {}, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  def staff_headers
    auth_headers(staff)
  end
end
