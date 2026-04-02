# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    redirect_to matches_path
  end
end