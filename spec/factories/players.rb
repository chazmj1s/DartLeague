# spec/factories/players.rb
FactoryBot.define do
  factory :player do
    sequence(:name) { |n| "Player #{n}" }
    gender { "male" }
    active { true }

    trait :female do
      gender { "female" }
    end

    trait :male do
      gender { "male" }
    end

    trait :inactive do
      active { false }
    end
  end
end
