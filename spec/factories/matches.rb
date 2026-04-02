# spec/factories/matches.rb
FactoryBot.define do
  factory :match do
    sequence(:opponent) { |n| "Opponent Pub #{n}" }
    match_date { Date.today + 7 }
    location   { "home" }
    status     { "draft" }

    trait :finalized do
      status { "finalized" }
    end

    trait :completed do
      status { "completed" }
    end

    # Build with the standard 11-game slate (no players assigned)
    trait :with_slate do
      after(:build) do |match|
        match.games = Match::STANDARD_GAMES.each_with_index.map do |(type, format), i|
          build(:game, match: match, game_type: type, format: format, sequence: i + 1)
        end
      end
    end
  end
end

# spec/factories/games.rb
FactoryBot.define do
  factory :game do
    association :match
    game_type { "singles_cricket" }
    format    { "singles" }
    status    { "unassigned" }
    sequence(:sequence) { |n| n }
  end
end

# spec/factories/absences.rb
FactoryBot.define do
  factory :absence do
    association :match
    association :player
    reason { nil }
  end
end
