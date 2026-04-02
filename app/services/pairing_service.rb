# app/services/pairing_service.rb
#
# ═══════════════════════════════════════════════════════════════════════════
# OFFICIAL LEAGUE RULES
# ═══════════════════════════════════════════════════════════════════════════
#
#  Roster
#    • 4–8 players per team; at least 1 must be female
#
#  Female coverage (all three required every match)
#    • ≥1 woman plays in at least one singles game
#    • ≥1 woman plays in at least one doubles game
#    • ≥1 woman plays in the team game
#
#  Doubles
#    • No two players may partner together in more than one doubles game
#    • Any gender combination is permitted
#
#  Game type exclusivity
#    • No player may appear in both games of the same game type
#      e.g. a player in Singles Cricket game 1 cannot play Singles Cricket game 2
#
#  Load balancing
#    • Total player-game slots: 4×1 + 6×2 + 1×4 = 20
#    • Target load = 20 ÷ roster_size  (distribute as evenly as possible)
#    • The scheduler tracks each player's running slot count and always
#      picks the least-loaded eligible player(s) for each game
#
# ── SLOT DISTRIBUTION BY ROSTER SIZE ───────────────────────────────────────
#
#   4 players → 20 slots ÷ 4 = 5.00  → each plays exactly 5 games
#   5 players → 20 slots ÷ 5 = 4.00  → each plays exactly 4 games
#   6 players → 20 slots ÷ 6 = 3.33  → 2 play 4 games, 4 play 3 games
#   7 players → 20 slots ÷ 7 = 2.86  → 6 play 3 games, 1 plays 2 games
#   8 players → 20 slots ÷ 8 = 2.50  → 4 play 3 games, 4 play 2 games
#
# ═══════════════════════════════════════════════════════════════════════════

class PairingService
  class InsufficientPlayersError < StandardError; end
  class PairingImpossibleError   < StandardError; end

  TOTAL_SLOTS   = 20
  SINGLES_COUNT = 4
  DOUBLES_COUNT = 6
  TEAM_SIZE     = 4

  def initialize(match)
    @match   = match
    @players = Player.available_for(match).to_a
    @women   = @players.select(&:female?)
    @men     = @players.select(&:male?)
  end

  # ── Public API ─────────────────────────────────────────────────────────────

  # Assign all games. Clears any prior unfinished assignments first.
  # Raises InsufficientPlayersError or PairingImpossibleError on failure.
  def assign!
    validate!

    ActiveRecord::Base.transaction do
      clear_reassignable_games!
      run_assignment
    end

    true
  end

  # Returns the proposed schedule as an array of hashes without persisting.
  def preview
    validate!
    build_schedule.map { |game, players| { game: game, players: players } }
  end

  # Human-readable summary of load distribution after assignment.
  def load_summary
    validate!
    load     = fresh_load_counter
    schedule = build_schedule(load)
    schedule.map { |game, players|
      { game: game.display_name, players: players.map(&:name) }
    }.tap do
      puts "\nLoad distribution:"
      load.sort_by { |_, v| -v }.each do |player, count|
        puts "  #{player.name.ljust(10)} #{count} games"
      end
    end
  end

  def roster_summary
    {
      total:       @players.size,
      women:       @women.size,
      men:         @men.size,
      total_slots: TOTAL_SLOTS,
      target_load: (TOTAL_SLOTS.to_f / @players.size).round(2),
      valid_pairs: @players.combination(2).count
    }
  end

  private

  # ── Validation ──────────────────────────────────────────────────────────────

  def validate!
    n = @players.size

    raise InsufficientPlayersError,
          "#{n} player(s) available; minimum is #{Player::MIN_ROSTER}." \
      if n < Player::MIN_ROSTER

    raise InsufficientPlayersError,
          "No female players are available. At least one woman must play each match." \
      if @women.empty?

    # 6 doubles games need 6 unique pairs; C(n,2) must be ≥ 6
    min_for_doubles = min_players_for_unique_doubles(DOUBLES_COUNT)
    raise PairingImpossibleError,
          "Need at least #{min_for_doubles} players to fill #{DOUBLES_COUNT} unique doubles pairs; " \
            "only #{n} available." \
      if n < min_for_doubles
  end

  # Minimum n such that C(n,2) >= doubles_count
  def min_players_for_unique_doubles(doubles_count)
    n = 2
    n += 1 until (n * (n - 1) / 2) >= doubles_count
    n
  end

  # ── Core scheduling ─────────────────────────────────────────────────────────

  # Returns an array of [game, [players]] in sequence order.
  # Accepts an optional pre-seeded load counter (used by preview/load_summary).
  def build_schedule(load = nil)
    load         ||= fresh_load_counter
    used_pairs     = Set.new                        # sorted [id,id] pairs already partnered
    female_cover   = { singles: false, doubles: false, team: false }
    type_usage     = Hash.new { |h, k| h[k] = [] } # game_type => [players already assigned]

    schedule = []

    @match.games.by_sequence.each do |game|
      players = case game.format
                when "singles"
                  pick_singles(game, load, female_cover, type_usage)
                when "doubles"
                  pick_doubles(game, load, used_pairs, female_cover, type_usage)
                when "team"
                  pick_team(game, load, female_cover)
                end

      # Record load
      players.each { |p| load[p] += 1 }

      # Record which players have now played this game type
      type_usage[game.game_type].concat(players)

      # Mark pairs used
      players.combination(2).each { |pair| used_pairs << pair.map(&:id).sort }

      schedule << [game, players]
    end

    schedule
  end

  # ── Singles picker ──────────────────────────────────────────────────────────
  # Pick the least-loaded player who has not already played this game type.
  # If female singles coverage is still unmet, prefer a woman.

  def pick_singles(game, load, female_cover, type_usage)
    already_played = type_usage[game.game_type]

    pool = @players
             .reject { |p| already_played.include?(p) }
             .sort_by { |p| [load[p], p.rank] }

    player = if !female_cover[:singles]
               woman    = pool.find(&:female?)
               min_load = load[pool.first]
               if woman && load[woman] <= min_load + 1
                 female_cover[:singles] = true
                 woman
               else
                 pool.first
               end
             else
               pool.first
             end

    female_cover[:singles] = true if player.female?
    [player]
  end

  # ── Doubles picker ──────────────────────────────────────────────────────────
  # Pick the two least-loaded players who:
  #   • have not already played this game type
  #   • have not already been partnered together this match
  # If female doubles coverage is still unmet, ensure at least one woman.

  def pick_doubles(game, load, used_pairs, female_cover, type_usage)
    already_played    = type_usage[game.game_type]
    remaining_doubles = @match.games.doubles.count -
                        @match.games.doubles.where(status: "assigned").count

    need_female_now = !female_cover[:doubles] &&
                      must_place_female_now?(@women, load, remaining_doubles)

    pair = if need_female_now
             pick_pair_with_female(load, used_pairs, already_played)
           else
             pick_best_pair(load, used_pairs, already_played)
           end

    raise PairingImpossibleError,
          "Cannot build a unique doubles pair for #{game.display_name} " \
            "from the available players." unless pair

    female_cover[:doubles] = true if pair.any?(&:female?)
    pair
  end

  # ── Team picker ─────────────────────────────────────────────────────────────
  # Pick 4 players. Ensure ≥1 woman is included (rule requires it).
  # Among valid selections, prefer the 4 least-loaded players.
  # (Only one team game exists so no type_usage exclusion needed.)

  def pick_team(_game, load, female_cover)
    by_load = @players.sort_by { |p| [load[p], p.rank] }
    candidates = by_load.first(TEAM_SIZE)

    unless candidates.any?(&:female?)
      woman      = by_load.find { |p| p.female? && !candidates.include?(p) }
      swap_out   = candidates.max_by { |p| load[p] }
      candidates = (candidates - [swap_out] + [woman]).compact
    end

    female_cover[:team] = true if candidates.any?(&:female?)
    candidates.first(TEAM_SIZE)
  end

  # ── Pair selection helpers ──────────────────────────────────────────────────

  # Best pair = lowest combined load, unique partnership, not already
  # assigned to this game type.
  def pick_best_pair(load, used_pairs, already_played = [])
    @players
      .reject { |p| already_played.include?(p) }
      .combination(2)
      .reject { |a, b| used_pairs.include?([a.id, b.id].sort) }
      .min_by { |a, b| [load[a] + load[b], a.rank + b.rank] }
  end

  # Best pair that includes at least one woman, unique partnership, not
  # already assigned to this game type.
  def pick_pair_with_female(load, used_pairs, already_played = [])
    @players
      .reject { |p| already_played.include?(p) }
      .combination(2)
      .select { |a, b| a.female? || b.female? }
      .reject { |a, b| used_pairs.include?([a.id, b.id].sort) }
      .min_by { |a, b| [load[a] + load[b], a.rank + b.rank] }
  end

  # Returns true when we are down to the last doubles slot and female
  # doubles coverage has not yet been met.
  def must_place_female_now?(_women, _load, remaining_slots)
    remaining_slots <= 1
  end

  # ── Persistence ─────────────────────────────────────────────────────────────

  def clear_reassignable_games!
    @match.games.where(status: %w[unassigned assigned]).each do |game|
      game.game_participants.destroy_all
      game.update!(status: "unassigned")
    end
  end

  def run_assignment
    load     = fresh_load_counter
    schedule = build_schedule(load)

    schedule.each do |game, players|
      players.each do |player|
        game.game_participants.create!(player: player, side: "home", role: "player")
      end
      game.update!(status: "assigned")
    end
  end

  def fresh_load_counter
    Hash.new(0).tap { |h| @players.each { |p| h[p] = 0 } }
  end
end