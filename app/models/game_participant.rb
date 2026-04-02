# app/models/game_participant.rb
class GameParticipant < ApplicationRecord
  belongs_to :game
  belongs_to :player

  validates :game_id,   presence: true
  validates :player_id, presence: true,
            uniqueness: { scope: :game_id, message: "is already in this game" }
end
