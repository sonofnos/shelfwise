class InventoryMailer < ApplicationMailer
  def low_stock(stock_item)
    @stock_item = stock_item
    @product = stock_item.product
    @warehouse = stock_item.warehouse

    mail(to: "warehouse-managers@shelfwise.test",
         subject: "Low stock: #{@product.sku} at #{@warehouse.code}")
  end
end
