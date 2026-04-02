# db/migrate/20240101000002_create_matches.rb
class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.string  :opponent,   null: false
      t.date    :match_date, null: false
      t.string  :location,   null: false, default: "home"   # 'home' | 'away'
      t.string  :status,     null: false, default: "draft"  # 'draft' | 'finalized' | 'completed'
      t.timestamps
    end
  end
end
