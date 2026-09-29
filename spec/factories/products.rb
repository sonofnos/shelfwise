FactoryBot.define do
  factory :product do
    sequence(:sku) { |n| "SKU#{n}" }
    name { "Widget" }
    price_cents { 2500 }
  end
end
