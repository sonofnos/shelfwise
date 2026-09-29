FactoryBot.define do
  factory :stock_item do
    product
    warehouse
    quantity_on_hand { 10 }
    quantity_reserved { 0 }
  end
end
