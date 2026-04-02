# db/migrate/20240101000001_create_players.rb
class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.string  :name,      null: false
      t.string  :gender,    null: false          # 'male' | 'female'
      t.boolean :active,    null: false, default: true
      t.timestamps
    end

    add_index :players, :name, unique: true
  end
end
