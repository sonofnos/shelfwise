FactoryBot.define do
  factory :warehouse do
    sequence(:code) { |n| "WH#{n}" }
    name { "Lagos Distribution Center" }
  end
end
