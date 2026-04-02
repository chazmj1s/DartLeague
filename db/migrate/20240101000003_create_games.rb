# db/migrate/20240101000003_create_games.rb
class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.references :match,    null: false, foreign_key: true
      t.string  :game_type,   null: false
      # game_type values:
      #   singles_cricket | singles_501
      #   doubles_chicago | doubles_cricket | doubles_501
      #   team_4player
      t.string  :format,      null: false   # 'singles' | 'doubles' | 'team'
      t.string  :status,      null: false, default: "unassigned"
      # 'unassigned' | 'assigned' | 'completed'
      t.integer :sequence,    null: false   # 1–11 display order
      t.integer :home_score
      t.integer :away_score
      t.timestamps
    end

    add_index :games, [:match_id, :sequence], unique: true
  end
end
