class Order < ApplicationRecord
  enum :status, { pending: 0, paid: 1, fulfilled: 2, cancelled: 3 }, default: :pending

  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :customer_name, presence: true
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :external_reference, presence: true, uniqueness: true

  # Idempotent on external_reference: replaying the same request (a retried
  # client call, a duplicate webhook-triggered order) returns the original
  # order instead of double-reserving stock or raising a uniqueness error.
  def self.place!(customer_name:, customer_email:, external_reference:, items:)
    existing = find_by(external_reference: external_reference)
    return existing if existing

    transaction do
      order = create!(customer_name: customer_name, customer_email: customer_email,
                       external_reference: external_reference, status: :pending)

      items.each do |item|
        StockItem.reserve!(product: item[:product], warehouse: item[:warehouse], quantity: item[:quantity])
        order.order_items.create!(product: item[:product], warehouse: item[:warehouse], quantity: item[:quantity])
      end

      order
    end
  end

  def mark_paid!
    update!(status: :paid)
  end

  def ship!
    transaction do
      order_items.each do |line|
        line.stock_item.fulfill!(line.quantity)
      end
      update!(status: :fulfilled)
    end
  end

  def cancel!
    return if fulfilled? || cancelled?

    transaction do
      order_items.each { |line| line.stock_item.release!(line.quantity) }
      update!(status: :cancelled)
    end
  end
end
