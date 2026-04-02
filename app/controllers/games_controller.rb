# app/controllers/games_controller.rb
class GamesController < ApplicationController
  before_action :set_match
  before_action :set_game

  # PATCH /matches/:match_id/games/:id
  # Manual override of player assignments for a specific game.
  def update
    ActiveRecord::Base.transaction do
      @game.game_participants.destroy_all

      player_ids = Array(params[:game][:player_ids]).map(&:to_i).compact.uniq
      validate_player_count!(player_ids)
      validate_female_coverage!(player_ids)

      player_ids.each do |pid|
        @game.game_participants.create!(player_id: pid, side: "home", role: "player")
      end
      @game.update!(status: "assigned")
    end

    redirect_to @match, notice: "Game #{@game.sequence} updated."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    redirect_to @match, alert: e.message
  end

  # PATCH /matches/:match_id/games/:id/complete
  def complete
    @game.update!(
      status:     "completed",
      home_score: params[:home_score],
      away_score: params[:away_score]
    )
    redirect_to @match, notice: "Score recorded for Game #{@game.sequence}."
  end

  private

  def set_match = @match = Match.find(params[:match_id])
  def set_game  = @game  = @match.games.find(params[:id])

  def validate_player_count!(ids)
    raise ArgumentError,
          "This game needs #{@game.player_count} player(s); you selected #{ids.size}." \
      unless ids.size == @game.player_count
  end

  # When manually editing: warn if this change would eliminate all female
  # representation from a game category, but only if women are on the roster.
  def validate_female_coverage!(ids)
    return unless Player.available_for(@match).any?(&:female?)

    players        = Player.where(id: ids)
    other_games    = @match.games.where.not(id: @game.id)
                           .where(format: @game.format)
                           .where(status: "assigned")

    female_elsewhere = other_games.joins(:game_participants)
                                  .joins("INNER JOIN players ON players.id = game_participants.player_id")
                                  .where(players: { gender: "female" })
                                  .exists?

    if players.none?(&:female?) && !female_elsewhere
      raise ArgumentError,
            "At least one female player must appear in a #{@game.format} game. " \
              "Please include a female player here or ensure another #{@game.format} game has one."
    end
  end
end
