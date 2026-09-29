class Product < ApplicationRecord
  has_many :stock_items, dependent: :destroy
  has_many :warehouses, through: :stock_items

  validates :sku, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :price_cents, numericality: { greater_than: 0 }

  before_save { self.sku = sku.upcase.strip }
end
