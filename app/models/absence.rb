# app/models/absence.rb
class Absence < ApplicationRecord
  belongs_to :match
  belongs_to :player

  validates :match_id,  presence: true
  validates :player_id, presence: true,
            uniqueness: { scope: :match_id,
                          message: "is already marked absent for this match" }
end
