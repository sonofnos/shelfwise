class LowStockAlertJob < ApplicationJob
  queue_as :default

  def perform(stock_item_id)
    stock_item = StockItem.find_by(id: stock_item_id)
    return if stock_item.nil?

    InventoryMailer.low_stock(stock_item).deliver_later
  end
end
