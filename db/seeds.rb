# db/seeds.rb
# ─────────────────────────────────────────────────────────────────────────────
# Seeds the roster and a 4-match schedule with mock data.
# Replace opponent names, dates, and locations with real data before go-live.
# Run with:  rails db:seed
# Reset and re-run:  rails db:seed:replant   (Rails 6+)
# ─────────────────────────────────────────────────────────────────────────────

puts "=" * 60
puts "Seeding Darts League..."
puts "=" * 60

# ── 1. Roster ─────────────────────────────────────────────────────────────────

puts "\n▸ Players..."

ROSTER = [
  { name: "Linda",   gender: "female", rank: 3 },
  { name: "Anita",   gender: "female", rank: 3 },
  { name: "Mike",    gender: "male",   rank: 1 },
  { name: "Dave",    gender: "male",   rank: 1 },
  { name: "Charlie", gender: "male",   rank: 2 },
  { name: "Ronnie",  gender: "male",   rank: 2 }
  # Two open slots — uncomment and rename when roster expands (max 8):
  # { name: "Player 7", gender: "female" },
  # { name: "Player 8", gender: "male"   },
].freeze

ROSTER.each do |attrs|
  Player.find_or_create_by!(name: attrs[:name]) { |p| p.gender = attrs[:gender] }
end

puts "  #{Player.active.count} players: " \
       "#{Player.active.ordered.map { |p| "#{p.name}" }.join(', ')}"

# ── 2. Match schedule ─────────────────────────────────────────────────────────
#
# Four matches spread across the season.
# *** Replace the opponent names, dates, and locations with real fixtures. ***
#
# Dates below are relative to today so the seed data is always in the future
# no matter when you run it. Swap Date.today + N for literal dates, e.g.:
#   match_date: Date.new(2025, 9, 12)

puts "\n▸ Matches..."

SCHEDULE = [
  {
    opponent:   "Elaine, Show Us Those Trips!",
    match_date: Date.new(2026,4, 7),
    location:   "Rags"
  },
  {
    opponent:   "It's Irrelevant",
    match_date: Date.new(2026,4, 14),
    location:   "Top Spin"
  },
  {
    opponent:   "Diddler & Co.",
    match_date: Date.new(2026,4, 21),
    location:   "Crown & Anchor"
  },
  {
    opponent:   "Elaine, Show Us Those Trips!",
    match_date: Date.new(2026,4, 28),
    location:   "Top Spin"
  },
].freeze

SCHEDULE.each do |fixture|
  # Skip if a match against this opponent on this date already exists
  # so re-running seeds is safe
  next if Match.exists?(opponent: fixture[:opponent], match_date: fixture[:match_date])

  print "  Creating match vs #{fixture[:opponent]}..."

  match = Match.build_standard_slate(
    opponent:   fixture[:opponent],
    match_date: fixture[:match_date],
    location:   fixture[:location]
  )
  match.save!

  begin
    PairingService.new(match).assign!
    print " pairings assigned."
  rescue PairingService::InsufficientPlayersError,
    PairingService::PairingImpossibleError => e
    print " ⚠ could not assign pairings: #{e.message}"
  end

  puts
end

# ── 3. Summary ────────────────────────────────────────────────────────────────

puts "\n▸ Schedule summary:"

Match.order(:match_date).each do |match|
  assigned  = match.games.count { |g| g.status == "assigned"  }
  completed = match.games.count { |g| g.status == "completed" }
  puts "  #{match.match_date.strftime('%b %-d').ljust(8)} " \
         "#{match.location.capitalize.ljust(5)} " \
         "vs #{match.opponent.ljust(25)} " \
         "[#{assigned} assigned, #{completed} completed]"
end

puts "\nDone! #{Player.active.count} players, #{Match.count} matches seeded."
puts "=" * 60