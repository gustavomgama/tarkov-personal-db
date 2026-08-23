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

ActiveRecord::Schema[8.1].define(version: 2026_08_21_211000) do
  create_table "craft_items", force: :cascade do |t|
    t.integer "count"
    t.datetime "created_at", null: false
    t.integer "hideout_craft_id", null: false
    t.integer "item_id", null: false
    t.string "kind", null: false
    t.datetime "updated_at", null: false
    t.index ["hideout_craft_id", "item_id", "kind"], name: "index_craft_items_uniqueness", unique: true
    t.index ["hideout_craft_id"], name: "index_craft_items_on_hideout_craft_id"
    t.index ["item_id"], name: "index_craft_items_on_item_id"
  end

  create_table "hideout_crafts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration"
    t.integer "hideout_station_id", null: false
    t.integer "level"
    t.string "tid", null: false
    t.datetime "updated_at", null: false
    t.index ["hideout_station_id"], name: "index_hideout_crafts_on_hideout_station_id"
    t.index ["tid"], name: "index_hideout_crafts_on_tid", unique: true
  end

  create_table "hideout_item_requirements", force: :cascade do |t|
    t.integer "count"
    t.datetime "created_at", null: false
    t.integer "hideout_level_id", null: false
    t.integer "item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hideout_level_id", "item_id"], name: "idx_on_hideout_level_id_item_id_f9738f0439", unique: true
    t.index ["hideout_level_id"], name: "index_hideout_item_requirements_on_hideout_level_id"
    t.index ["item_id"], name: "index_hideout_item_requirements_on_item_id"
  end

  create_table "hideout_levels", force: :cascade do |t|
    t.integer "construction_time"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "hideout_station_id", null: false
    t.integer "level", null: false
    t.datetime "updated_at", null: false
    t.index ["hideout_station_id", "level"], name: "index_hideout_levels_on_hideout_station_id_and_level", unique: true
    t.index ["hideout_station_id"], name: "index_hideout_levels_on_hideout_station_id"
  end

  create_table "hideout_requirements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "hideout_level_id", null: false
    t.integer "level"
    t.string "requirement_type", null: false
    t.string "target_name", null: false
    t.datetime "updated_at", null: false
    t.index ["hideout_level_id", "requirement_type", "target_name"], name: "idx_on_hideout_level_id_requirement_type_target_nam_12c2b17ea3", unique: true
    t.index ["hideout_level_id"], name: "index_hideout_requirements_on_hideout_level_id"
  end

  create_table "hideout_stations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "normalized_name"
    t.string "tid", null: false
    t.datetime "updated_at", null: false
    t.index ["normalized_name"], name: "index_hideout_stations_on_normalized_name"
    t.index ["tid"], name: "index_hideout_stations_on_tid", unique: true
  end

  create_table "item_unlocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "item_id", null: false
    t.string "item_name", null: false
    t.integer "loyalty_level"
    t.integer "task_id"
    t.integer "trader_id"
    t.string "trader_name"
    t.text "unlock_types", default: "[]", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "task_id"], name: "index_item_unlocks_item_task"
    t.index ["item_id"], name: "index_item_unlocks_on_item_id"
    t.index ["task_id"], name: "index_item_unlocks_on_task_id"
    t.index ["trader_id"], name: "index_item_unlocks_on_trader_id"
  end

  create_table "items", force: :cascade do |t|
    t.boolean "barter", default: false, null: false
    t.string "category"
    t.boolean "craft", default: false, null: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "grid_image_link"
    t.string "icon_link"
    t.string "name", null: false
    t.decimal "price", precision: 14, scale: 2
    t.boolean "quest_item", default: false, null: false
    t.boolean "require_unlock", default: false, null: false
    t.string "tid", null: false
    t.datetime "updated_at", null: false
    t.string "wiki_link"
    t.index ["tid"], name: "index_items_on_tid", unique: true
  end

  create_table "sync_states", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "synced_at", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
  end

  create_table "task_objectives", force: :cascade do |t|
    t.integer "count"
    t.datetime "created_at", null: false
    t.boolean "found_in_raid", default: false
    t.integer "item_id", null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_task_objectives_on_item_id"
    t.index ["task_id", "item_id"], name: "index_task_objectives_on_task_id_and_item_id", unique: true
    t.index ["task_id"], name: "index_task_objectives_on_task_id"
  end

  create_table "task_requirements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "required_task_id", null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["required_task_id"], name: "index_task_requirements_on_required_task_id"
    t.index ["task_id", "required_task_id"], name: "index_task_requirements_on_task_id_and_required_task_id", unique: true
    t.index ["task_id"], name: "index_task_requirements_on_task_id"
  end

  create_table "task_rewards", force: :cascade do |t|
    t.integer "count"
    t.datetime "created_at", null: false
    t.integer "item_id", null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_task_rewards_on_item_id"
    t.index ["task_id", "item_id"], name: "index_task_rewards_on_task_id_and_item_id", unique: true
    t.index ["task_id"], name: "index_task_rewards_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "kappa_required", default: false
    t.boolean "lightkeeper_required", default: false, null: false
    t.integer "min_player_level"
    t.string "name", null: false
    t.integer "next_task_id"
    t.string "next_task_name"
    t.integer "previous_task_id"
    t.string "previous_task_name"
    t.string "previous_task_title"
    t.string "tid", null: false
    t.integer "trader_id"
    t.datetime "updated_at", null: false
    t.string "wiki_link"
    t.index ["tid"], name: "index_tasks_on_tid", unique: true
    t.index ["trader_id"], name: "index_tasks_on_trader_id"
  end

  create_table "trader_loyalty_levels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level", null: false
    t.integer "required_player_level"
    t.decimal "required_reputation", precision: 8, scale: 2
    t.integer "trader_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trader_id", "level"], name: "index_trader_loyalty_levels_on_trader_id_and_level", unique: true
    t.index ["trader_id"], name: "index_trader_loyalty_levels_on_trader_id"
  end

  create_table "traders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "reset_time"
    t.string "tid", null: false
    t.datetime "updated_at", null: false
    t.index ["tid"], name: "index_traders_on_tid", unique: true
  end

  add_foreign_key "craft_items", "hideout_crafts"
  add_foreign_key "craft_items", "items"
  add_foreign_key "hideout_crafts", "hideout_stations"
  add_foreign_key "hideout_item_requirements", "hideout_levels"
  add_foreign_key "hideout_item_requirements", "items"
  add_foreign_key "hideout_levels", "hideout_stations"
  add_foreign_key "hideout_requirements", "hideout_levels"
  add_foreign_key "item_unlocks", "items"
  add_foreign_key "item_unlocks", "tasks"
  add_foreign_key "item_unlocks", "traders"
  add_foreign_key "task_objectives", "items"
  add_foreign_key "task_objectives", "tasks"
  add_foreign_key "task_requirements", "tasks"
  add_foreign_key "task_requirements", "tasks", column: "required_task_id"
  add_foreign_key "task_rewards", "items"
  add_foreign_key "task_rewards", "tasks"
  add_foreign_key "tasks", "traders"
  add_foreign_key "trader_loyalty_levels", "traders"
end
