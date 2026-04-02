# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2024_01_02_000001) do
  create_table "absences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "match_id", null: false
    t.integer "player_id", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["match_id", "player_id"], name: "index_absences_on_match_id_and_player_id", unique: true
    t.index ["match_id"], name: "index_absences_on_match_id"
    t.index ["player_id"], name: "index_absences_on_player_id"
  end

  create_table "game_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "player_id", null: false
    t.string "role", default: "player", null: false
    t.string "side", default: "home", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "player_id"], name: "index_game_participants_on_game_id_and_player_id", unique: true
    t.index ["game_id"], name: "index_game_participants_on_game_id"
    t.index ["player_id"], name: "index_game_participants_on_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "away_score"
    t.datetime "created_at", null: false
    t.string "format", null: false
    t.string "game_type", null: false
    t.integer "home_score"
    t.integer "match_id", null: false
    t.integer "sequence", null: false
    t.string "status", default: "unassigned", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id", "sequence"], name: "index_games_on_match_id_and_sequence", unique: true
    t.index ["match_id"], name: "index_games_on_match_id"
  end

  create_table "matches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location", default: "home", null: false
    t.date "match_date", null: false
    t.string "opponent", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "gender", null: false
    t.string "name", null: false
    t.integer "rank", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_players_on_name", unique: true
    t.index ["rank"], name: "index_players_on_rank"
  end

  add_foreign_key "absences", "matches"
  add_foreign_key "absences", "players"
  add_foreign_key "game_participants", "games"
  add_foreign_key "game_participants", "players"
  add_foreign_key "games", "matches"
end
