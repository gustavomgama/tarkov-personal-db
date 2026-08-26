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

ActiveRecord::Schema[8.1].define(version: 2026_08_26_020000) do
  create_table "item_aliases", force: :cascade do |t|
    t.string "canonical_tid", null: false
    t.datetime "created_at", null: false
    t.string "tid", null: false
    t.datetime "updated_at", null: false
    t.index ["tid"], name: "index_item_aliases_on_tid", unique: true
  end

  create_table "item_unlocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.integer "item_id", null: false
    t.string "item_name", null: false
    t.integer "loyalty_level"
    t.json "required_items", default: {}, null: false
    t.string "source", default: "wiki", null: false
    t.string "source_variant"
    t.string "station"
    t.integer "station_level"
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
    t.text "allowed_ammo", default: "[]", null: false
    t.boolean "ammo", default: false, null: false
    t.integer "armor_class"
    t.boolean "barter", default: false, null: false
    t.string "caliber"
    t.text "categories"
    t.text "compat", default: "{}", null: false
    t.boolean "craft", default: false, null: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.integer "damage"
    t.boolean "gun", default: false, null: false
    t.string "icon_link"
    t.string "image_link"
    t.string "name", null: false
    t.integer "penetration_power"
    t.decimal "price", precision: 14, scale: 2
    t.boolean "ref_gp", default: false, null: false
    t.boolean "require_unlock", default: false, null: false
    t.string "slug"
    t.string "tid", null: false
    t.datetime "updated_at", null: false
    t.string "wiki_link"
    t.index "LOWER(name)", name: "index_items_on_lower_name"
    t.index ["currency"], name: "index_items_on_currency"
    t.index ["price"], name: "index_items_on_price"
    t.index ["ref_gp"], name: "index_items_on_ref_gp"
    t.index ["slug"], name: "index_items_on_slug"
    t.index ["tid"], name: "index_items_on_tid", unique: true
  end

  create_table "sync_states", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "synced_at", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
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
    t.string "slug"
    t.string "tid", null: false
    t.integer "trader_id"
    t.datetime "updated_at", null: false
    t.string "wiki_link"
    t.index "LOWER(name)", name: "index_tasks_on_lower_name"
    t.index ["min_player_level"], name: "index_tasks_on_min_player_level"
    t.index ["slug"], name: "index_tasks_on_slug"
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
    t.string "image_url"
    t.string "name", null: false
    t.datetime "reset_time"
    t.string "slug"
    t.string "tid", null: false
    t.datetime "updated_at", null: false
    t.index ["tid"], name: "index_traders_on_tid", unique: true
  end

  add_foreign_key "item_unlocks", "items"
  add_foreign_key "item_unlocks", "tasks"
  add_foreign_key "item_unlocks", "traders"
  add_foreign_key "task_requirements", "tasks"
  add_foreign_key "task_requirements", "tasks", column: "required_task_id"
  add_foreign_key "tasks", "traders"
  add_foreign_key "trader_loyalty_levels", "traders"
end
