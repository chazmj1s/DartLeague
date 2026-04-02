# app/controllers/matches_controller.rb
class MatchesController < ApplicationController
  before_action :set_match, only: %i[show edit update destroy finalize reassign]

  def index
    @matches = Match.order(match_date: :asc)
  end

  def show
    @games   = @match.games.by_sequence.includes(:players)
    @absent  = @match.absent_players
    @players = Player.active.ordered
    @load    = @match.load_report
  end

  def new
    @match = Match.build_standard_slate(opponent: "", match_date: Date.today)
  end

  def create
    @match = Match.build_standard_slate(
      opponent:   match_params[:opponent],
      match_date: match_params[:match_date],
      location:   match_params[:location]
    )
    if @match.save
      redirect_to @match, notice: "Match created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @match.update(match_params)
      redirect_to @match, notice: "Match updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @match.destroy
    redirect_to matches_path, notice: "Match deleted."
  end

  # POST /matches/:id/finalize
  def finalize
    @match.update!(status: "finalized")
    redirect_to @match, notice: "Lineup locked in!"
  end

  # POST /matches/:id/reassign
  def reassign
    PairingService.new(@match).assign!
    redirect_to @match, notice: "Pairings updated."
  rescue PairingService::InsufficientPlayersError,
    PairingService::PairingImpossibleError => e
    redirect_to @match, alert: e.message
  end

  private

  def set_match = @match = Match.find(params[:id])

  def match_params
    params.require(:match).permit(:opponent, :match_date, :location, :status)
  end
end