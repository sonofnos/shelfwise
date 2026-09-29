require "rails_helper"

RSpec.describe Order, type: :model do
  let(:warehouse) { create(:warehouse) }
  let(:product) { create(:product) }

  before { create(:stock_item, product: product, warehouse: warehouse, quantity_on_hand: 10) }

  describe ".place!" do
    it "creates the order and reserves stock for each line" do
      order = Order.place!(
        customer_name: "Ada Lovelace",
        customer_email: "ada@example.com",
        external_reference: "ref-1",
        items: [ { product: product, warehouse: warehouse, quantity: 3 } ]
      )

      expect(order).to be_persisted
      expect(order.order_items.sole.quantity).to eq(3)
      expect(StockItem.find_by(product: product, warehouse: warehouse).quantity_reserved).to eq(3)
    end

    it "is idempotent on external_reference" do
      attrs = { customer_name: "Ada", customer_email: "ada@example.com", external_reference: "ref-2",
                items: [ { product: product, warehouse: warehouse, quantity: 2 } ] }

      first = Order.place!(**attrs)
      second = Order.place!(**attrs)

      expect(second.id).to eq(first.id)
      expect(StockItem.find_by(product: product, warehouse: warehouse).quantity_reserved).to eq(2)
    end

    it "reserves nothing if any line in the order is out of stock" do
      other_product = create(:product)

      expect {
        Order.place!(
          customer_name: "Ada", customer_email: "ada@example.com", external_reference: "ref-3",
          items: [
            { product: product, warehouse: warehouse, quantity: 2 },
            { product: other_product, warehouse: warehouse, quantity: 1 }
          ]
        )
      }.to raise_error(ActiveRecord::RecordNotFound) # no stock_item row for other_product at all

      expect(StockItem.find_by(product: product, warehouse: warehouse).quantity_reserved).to eq(0)
      expect(Order.find_by(external_reference: "ref-3")).to be_nil
    end
  end

  describe "#cancel!" do
    it "releases reserved stock" do
      order = Order.place!(customer_name: "Ada", customer_email: "ada@example.com", external_reference: "ref-4",
                            items: [ { product: product, warehouse: warehouse, quantity: 4 } ])

      order.cancel!

      expect(order).to be_cancelled
      expect(StockItem.find_by(product: product, warehouse: warehouse).quantity_reserved).to eq(0)
    end
  end

  describe "#ship!" do
    it "fulfills stock and marks the order fulfilled" do
      order = Order.place!(customer_name: "Ada", customer_email: "ada@example.com", external_reference: "ref-5",
                            items: [ { product: product, warehouse: warehouse, quantity: 4 } ])

      order.ship!

      expect(order).to be_fulfilled
      item = StockItem.find_by(product: product, warehouse: warehouse)
      expect(item.quantity_on_hand).to eq(6)
      expect(item.quantity_reserved).to eq(0)
    end
  end
end
