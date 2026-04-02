# db/migrate/20240101000004_create_game_participants.rb
class CreateGameParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :game_participants do |t|
      t.references :game,   null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :side,  null: false, default: "home"    # 'home' | 'away'
      t.string :role,  null: false, default: "player"
      t.timestamps
    end

    # A player can only appear once per game
    add_index :game_participants, [:game_id, :player_id], unique: true
  end
end
