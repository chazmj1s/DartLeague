# app/models/game.rb
class Game < ApplicationRecord
  GAME_TYPES = %w[
    singles_cricket singles_501
    doubles_chicago doubles_cricket doubles_501
    team_4player
  ].freeze

  FORMATS  = %w[singles doubles team].freeze
  STATUSES = %w[unassigned assigned completed].freeze

  belongs_to :match
  has_many   :game_participants, dependent: :destroy
  has_many   :players, through: :game_participants

  validates :game_type, inclusion: { in: GAME_TYPES }
  validates :format,    inclusion: { in: FORMATS }
  validates :status,    inclusion: { in: STATUSES }

  scope :singles,     -> { where(format: "singles") }
  scope :doubles,     -> { where(format: "doubles") }
  scope :team,        -> { where(format: "team") }
  scope :by_sequence, -> { order(:sequence) }

  def assigned?  = status != "unassigned"
  def completed? = status == "completed"

  def home_players
    game_participants.where(side: "home").includes(:player).map(&:player)
  end

  def player_count
    case format
    when "singles" then 1
    when "doubles" then 2
    when "team"    then 4
    end
  end

  def display_name
    game_type.humanize
  end

  def format_icon
    case format
    when "singles" then "🎯"
    when "doubles" then "👥"
    when "team"    then "🏆"
    end
  end
end

