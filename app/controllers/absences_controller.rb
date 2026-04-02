# app/controllers/absences_controller.rb
class AbsencesController < ApplicationController
  before_action :set_match

  # POST /matches/:match_id/absences
  def create
    absence = @match.absences.build(player_id: params[:player_id],
                                    reason:    params[:reason])
    if absence.save
      unless @match.finalized?
        PairingService.new(@match).assign!
      end
      redirect_to @match, notice: "#{absence.player.name} marked absent. Pairings updated."
    else
      redirect_to @match, alert: absence.errors.full_messages.to_sentence
    end
  rescue PairingService::InsufficientPlayersError,
    PairingService::PairingImpossibleError => e
    redirect_to @match, alert: "Could not reassign: #{e.message}"
  end

  # DELETE /matches/:match_id/absences/:id
  def destroy
    absence     = @match.absences.find(params[:id])
    player_name = absence.player.name
    absence.destroy

    unless @match.finalized?
      PairingService.new(@match).assign!
    end
    redirect_to @match, notice: "#{player_name} marked present. Pairings updated."
  rescue PairingService::InsufficientPlayersError,
    PairingService::PairingImpossibleError => e
    redirect_to @match, alert: "Could not reassign: #{e.message}"
  end

  private

  def set_match = @match = Match.find(params[:match_id])
end
