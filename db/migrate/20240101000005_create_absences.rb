# db/migrate/20240101000005_create_absences.rb
class CreateAbsences < ActiveRecord::Migration[7.1]
  def change
    create_table :absences do |t|
      t.references :match,  null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string :reason
      t.timestamps
    end

    # A player can only be marked absent once per match
    add_index :absences, [:match_id, :player_id], unique: true
  end
end
