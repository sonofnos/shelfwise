# Preview all emails at http://localhost:3000/rails/mailers/inventory_mailer_mailer
class InventoryMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/inventory_mailer_mailer/low_stock
  def low_stock
    InventoryMailer.low_stock(StockItem.first || FactoryBot.create(:stock_item))
  end
end
