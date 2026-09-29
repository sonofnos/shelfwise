class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :warehouse

  validates :quantity, numericality: { greater_than: 0 }

  def stock_item
    StockItem.find_by!(product: product, warehouse: warehouse)
  end
end
