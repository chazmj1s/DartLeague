# app/models/match.rb
#
# Represents a single match night against an opponent.
# Builds and manages the standard 11-game slate.
#
# Official game slate:
#   2× Singles Cricket   (singles format)
#   2× Singles 501       (singles format)
#   2× Doubles Chicago   (doubles format)
#   2× Doubles Cricket   (doubles format)
#   2× Doubles 501       (doubles format)
#   1× Team 4-player     (team format)
#
class Match < ApplicationRecord
  STATUSES  = %w[draft finalized completed].freeze
  LOCATIONS = %w[home away].freeze

  has_many :games,    dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :absent_players, through: :absences, source: :player

  validates :match_date, presence: true
  validates :opponent,   presence: true
  validates :status,     inclusion: { in: STATUSES }

  STANDARD_GAMES = [
    # [game_type,         format]
    ["singles_cricket",  "singles"],
    ["singles_cricket",  "singles"],
    ["singles_501",      "singles"],
    ["singles_501",      "singles"],
    ["doubles_chicago",  "doubles"],
    ["doubles_chicago",  "doubles"],
    ["doubles_cricket",  "doubles"],
    ["doubles_cricket",  "doubles"],
    ["doubles_501",      "doubles"],
    ["doubles_501",      "doubles"],
    ["team_4player",     "team"],
  ].freeze

  # Build the full 11-game slate without assigning players yet
  def self.build_standard_slate(opponent:, match_date:, location: "home")
    match = new(opponent: opponent, match_date: match_date, location: location)
    STANDARD_GAMES.each_with_index do |(type, format), i|
      match.games.build(game_type: type, format: format, sequence: i + 1)
    end
    match
  end

  def available_players = Player.available_for(self)
  def finalized?        = status == "finalized"
  def completed?        = status == "completed"

  def reassign_pairings!
    PairingService.new(self).assign!
  end

  # Returns a hash of player => game_count for the current assignment
  def load_report
    available_players.index_with do |player|
      games.joins(:game_participants)
           .where(game_participants: { player_id: player.id })
           .count
    end
  end
end
