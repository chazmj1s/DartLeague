# app/models/player.rb
#
# Official league rules:
#   - Roster: 4–8 players, at least 1 must be female
#   - No gender restriction on who can partner whom in doubles
#   - A female player must appear in ≥1 singles, ≥1 doubles, and ≥1 team game
#
class Player < ApplicationRecord
  GENDERS    = %w[male female].freeze
  MIN_ROSTER = 4
  MAX_ROSTER = 8

  has_many :game_participants, dependent: :destroy
  has_many :games, through: :game_participants
  has_many :absences, dependent: :destroy

  validates :name,   presence: true, uniqueness: { case_sensitive: false }
  validates :rank, numericality: { only_integer: true,
                                   greater_than_or_equal_to: 1,
                                   less_than_or_equal_to: 3 }
  validates :gender, inclusion: { in: GENDERS }
  validate  :roster_not_full, on: :create

  scope :active,  -> { where(active: true) }
  scope :male,    -> { where(gender: "male") }
  scope :female,  -> { where(gender: "female") }
  scope :ordered, -> { order(rank: :asc, name: :asc) }
  scope :by_rank, -> { order(rank: :asc, name: :asc) }

  # All active players who are not marked absent for the given match
  def self.available_for(match)
    absent_ids = match.absences.pluck(:player_id)
    active.where.not(id: absent_ids).order(:name)
  end

  def male?         = gender == "male"
  def female?       = gender == "female"
  def gender_label  = female? ? "F" : "M"

  private

  def roster_not_full
    errors.add(:base, "Roster is full (max #{MAX_ROSTER} active players).") \
      if Player.active.count >= MAX_ROSTER
  end
end
