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

ActiveRecord::Schema[8.1].define(version: 2026_08_21_190500) do
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

  create_table "items", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "grid_image_link"
    t.integer "height"
    t.string "icon_link"
    t.string "name", null: false
    t.string "short_name"
    t.string "tid", null: false
    t.text "types", default: "[]"
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 8, scale: 3
    t.integer "width"
    t.string "wiki_link"
    t.index ["tid"], name: "index_items_on_tid", unique: true
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

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "kappa_required", default: false
    t.integer "min_player_level"
    t.string "name", null: false
    t.string "tid", null: false
    t.integer "trader_id"
    t.datetime "updated_at", null: false
    t.string "wiki_link"
    t.index ["tid"], name: "index_tasks_on_tid", unique: true
    t.index ["trader_id"], name: "index_tasks_on_trader_id"
  end

  create_table "trader_items", force: :cascade do |t|
    t.boolean "barter", default: false, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "RUB", null: false
    t.integer "item_id", null: false
    t.integer "min_trader_level"
    t.decimal "price", precision: 10, scale: 2
    t.integer "trader_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_trader_items_on_item_id"
    t.index ["trader_id", "item_id"], name: "index_trader_items_on_trader_id_and_item_id", unique: true
    t.index ["trader_id"], name: "index_trader_items_on_trader_id"
  end

  create_table "traders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "RUB", null: false
    t.text "description"
    t.string "name", null: false
    t.string "normalized_name"
    t.datetime "reset_time"
    t.string "tid", null: false
    t.datetime "updated_at", null: false
    t.index ["normalized_name"], name: "index_traders_on_normalized_name"
    t.index ["tid"], name: "index_traders_on_tid", unique: true
  end

  add_foreign_key "hideout_item_requirements", "hideout_levels"
  add_foreign_key "hideout_item_requirements", "items"
  add_foreign_key "hideout_levels", "hideout_stations"
  add_foreign_key "hideout_requirements", "hideout_levels"
  add_foreign_key "task_objectives", "items"
  add_foreign_key "task_objectives", "tasks"
  add_foreign_key "tasks", "traders"
  add_foreign_key "trader_items", "items"
  add_foreign_key "trader_items", "traders"
end
