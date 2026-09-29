require "rails_helper"

RSpec.describe StockItem, type: :model do
  describe "#available" do
    it "is on-hand minus reserved" do
      item = create(:stock_item, quantity_on_hand: 10, quantity_reserved: 3)

      expect(item.available).to eq(7)
    end
  end

  describe ".reserve!" do
    let(:product) { create(:product) }
    let(:warehouse) { create(:warehouse) }

    it "increments reserved quantity when there's enough headroom" do
      create(:stock_item, product: product, warehouse: warehouse, quantity_on_hand: 10, quantity_reserved: 0)

      item = StockItem.reserve!(product: product, warehouse: warehouse, quantity: 4)

      expect(item.quantity_reserved).to eq(4)
    end

    it "raises when there isn't enough available stock" do
      create(:stock_item, product: product, warehouse: warehouse, quantity_on_hand: 3, quantity_reserved: 0)

      expect {
        StockItem.reserve!(product: product, warehouse: warehouse, quantity: 5)
      }.to raise_error(StockItem::InsufficientStockError)
    end

    # Regression test for overselling: ten concurrent reservations against
    # five units of stock, each on its own DB connection. Exactly five should
    # win; the CHECK constraint plus row lock must stop the rest, not just
    # the application-level check (which alone can't survive true concurrent
    # connections racing past "is there enough?" at the same instant).
    it "never lets total reservations exceed on-hand stock under concurrency", :no_transaction do
      create(:stock_item, product: product, warehouse: warehouse, quantity_on_hand: 5, quantity_reserved: 0)
      results = Queue.new

      threads = Array.new(10) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            StockItem.reserve!(product: product, warehouse: warehouse, quantity: 1)
            results << :reserved
          rescue StockItem::InsufficientStockError
            results << :rejected
          end
        end
      end
      threads.each(&:join)

      outcomes = Array.new(10) { results.pop }
      expect(outcomes.count(:reserved)).to eq(5)
      expect(outcomes.count(:rejected)).to eq(5)

      item = StockItem.find_by!(product: product, warehouse: warehouse)
      expect(item.quantity_reserved).to eq(5)
      expect(item.quantity_reserved).to be <= item.quantity_on_hand
    end
  end

  describe "#fulfill!" do
    it "deducts on-hand and reserved stock together" do
      item = create(:stock_item, quantity_on_hand: 10, quantity_reserved: 4)

      item.fulfill!(4)

      expect(item.reload.quantity_on_hand).to eq(6)
      expect(item.quantity_reserved).to eq(0)
    end

    it "queues a low stock alert once on-hand drops to the threshold" do
      item = create(:stock_item, quantity_on_hand: 6, quantity_reserved: 5)

      expect { item.fulfill!(5) }.to have_enqueued_job(LowStockAlertJob).with(item.id)
    end
  end
end
