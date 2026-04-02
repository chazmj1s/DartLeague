# app/controllers/players_controller.rb
class PlayersController < ApplicationController
  before_action :set_player, only: %i[edit update destroy]

  def index
    @players = Player.active.ordered
    @stats   = {
      total:  @players.count,
      female: @players.count(&:female?),
      male:   @players.count(&:male?),
      open:   Player::MAX_ROSTER - @players.count
    }
  end

  def new
    @player = Player.new
  end

  def create
    @player = Player.new(player_params)
    if @player.save
      redirect_to players_path, notice: "#{@player.name} added to the roster."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @player.update(player_params)
      redirect_to players_path, notice: "#{@player.name} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @player.update!(active: false)
    redirect_to players_path, notice: "#{@player.name} removed from the roster."
  end

  private

  def set_player
    @player = Player.find(params[:id])
  end

  def player_params
    params.require(:player).permit(:name, :gender)
  end
end
