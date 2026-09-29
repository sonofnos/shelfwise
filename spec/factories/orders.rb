FactoryBot.define do
  factory :order do
    customer_name { Faker::Name.name }
    sequence(:customer_email) { |n| "customer#{n}@example.com" }
    sequence(:external_reference) { |n| "order-ref-#{n}" }
    status { :pending }
  end
end
