class Warehouse < ApplicationRecord
  has_many :stock_items, dependent: :destroy
  has_many :products, through: :stock_items

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { case_sensitive: false }

  before_save { self.code = code.upcase.strip }
end
