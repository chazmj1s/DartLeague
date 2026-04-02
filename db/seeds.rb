# db/seeds.rb
# Current roster: Linda (F), Anita (F), Mike (M), Dave (M), Charlie (M), Ronnie (M)

puts "Seeding players..."

[
  { name: "Linda",   gender: "female" },
  { name: "Anita",   gender: "female" },
  { name: "Mike",    gender: "male"   },
  { name: "Dave",    gender: "male"   },
  { name: "Charlie", gender: "male"   },
  { name: "Ronnie",  gender: "male"   },
  # Roster has 2 open slots (max 8). Uncomment to add:
  # { name: "Player7", gender: "female" },
  # { name: "Player8", gender: "male"   },
].each do |attrs|
  Player.find_or_create_by!(name: attrs[:name]) { |p| p.gender = attrs[:gender] }
end

puts "  #{Player.count} players: #{Player.ordered.map { |p| "#{p.name}(#{p.gender_label})" }.join(', ')}"

puts "Seeding sample match..."

match = Match.build_standard_slate(
  opponent:   "The Red Lion",
  match_date: Date.today + 7,
  location:   "home"
)
match.save!

puts "Assigning pairings..."
PairingService.new(match).assign!

summary = PairingService.new(match).roster_summary
puts "  #{summary[:total]} players, #{summary[:total_slots]} slots, " \
     "target load #{summary[:target_load]} games/player"

puts "\nGame assignments:"
match.games.by_sequence.each do |game|
  names = game.home_players.map { |p| "#{p.name}(#{p.gender_label})" }.join(" & ")
  puts "  #{game.sequence.to_s.rjust(2)}. #{game.display_name.ljust(20)} #{names}"
end

puts "\nLoad distribution:"
match.load_report.sort_by { |_, v| -v }.each do |player, count|
  puts "  #{player.name.ljust(10)} #{count} games"
end
