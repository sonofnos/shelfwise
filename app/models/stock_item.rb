class StockItem < ApplicationRecord
  class InsufficientStockError < StandardError; end

  LOW_STOCK_THRESHOLD = 5

  belongs_to :product
  belongs_to :warehouse

  validates :quantity_on_hand, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_reserved, numericality: { greater_than_or_equal_to: 0 }
  validate :reserved_within_on_hand

  def available
    quantity_on_hand - quantity_reserved
  end

  # Reserves stock for an order line. Locks this row for the duration of the
  # check-then-increment so two concurrent orders can't both see headroom and
  # both reserve it -- and the DB-level CHECK constraint from the migration
  # is the backstop if that lock is ever bypassed (e.g. a bulk update).
  def self.reserve!(product:, warehouse:, quantity:)
    transaction do
      item = lock.find_by!(product: product, warehouse: warehouse)

      raise InsufficientStockError, "Not enough stock of #{product.sku} at #{warehouse.code}" if item.available < quantity

      item.increment!(:quantity_reserved, quantity)
      item
    end
  rescue ActiveRecord::StatementInvalid => e
    raise unless e.cause.is_a?(PG::CheckViolation)

    raise InsufficientStockError, "Not enough stock of #{product.sku} at #{warehouse.code}"
  end

  def release!(quantity)
    with_lock do
      update!(quantity_reserved: quantity_reserved - quantity)
    end
  end

  # Called when an order actually ships: the reservation becomes a real
  # deduction from on-hand stock.
  def fulfill!(quantity)
    with_lock do
      update!(quantity_on_hand: quantity_on_hand - quantity, quantity_reserved: quantity_reserved - quantity)
    end

    LowStockAlertJob.perform_later(id) if reload.quantity_on_hand <= LOW_STOCK_THRESHOLD
  end

  private

  def reserved_within_on_hand
    return if quantity_on_hand.nil? || quantity_reserved.nil?

    errors.add(:quantity_reserved, "cannot exceed quantity on hand") if quantity_reserved > quantity_on_hand
  end
end
