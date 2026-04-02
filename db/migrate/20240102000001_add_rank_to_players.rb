class AddRankToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :rank, :integer, default: 1, null: false
    add_index  :players, :rank
  end
end