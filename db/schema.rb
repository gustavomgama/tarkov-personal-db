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

ActiveRecord::Schema[8.1].define(version: 2026_09_04_172553) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "barters", force: :cascade do |t|
    t.jsonb "requirements", default: [], null: false
    t.jsonb "result", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "buyables", force: :cascade do |t|
    t.string "item_id", null: false
    t.string "trader_name", null: false
    t.string "trader_level", null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_buyables_on_item_id"
    t.index ["trader_name"], name: "index_buyables_on_trader_name"
  end

  create_table "crafts", force: :cascade do |t|
    t.string "station", null: false
    t.string "station_level"
    t.jsonb "input_items", default: [], null: false
    t.jsonb "output_items", default: [], null: false
    t.string "task_requirements"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "items", force: :cascade do |t|
    t.string "bsg_id", null: false
    t.string "slug", null: false
    t.string "full_name", null: false
    t.string "short_name"
    t.jsonb "types", default: [], null: false
    t.jsonb "links", default: {}, null: false
    t.jsonb "images", default: {}, null: false
    t.jsonb "properties", default: {}, null: false
    t.jsonb "conflicting_items", default: [], null: false
    t.jsonb "conflicting_slot_ids", default: [], null: false
    t.jsonb "conflicting_categories", default: [], null: false
    t.jsonb "obtain_from", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "buyables", default: [], null: false
    t.jsonb "barteables", default: [], null: false
    t.jsonb "craftables", default: [], null: false
    t.index ["bsg_id"], name: "index_items_on_bsg_id", unique: true
    t.index ["slug"], name: "index_items_on_slug", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.string "bsg_id", null: false
    t.string "name", null: false
    t.string "full_name", null: false
    t.string "wiki_link", default: "", null: false
    t.string "given_by", null: false
    t.boolean "kappa_required", default: false, null: false
    t.boolean "lightkeeper_required", default: false, null: false
    t.jsonb "leads_to", default: [], null: false
    t.jsonb "requirements", default: [], null: false
    t.jsonb "start_rewards", default: [], null: false
    t.jsonb "finish_rewards", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bsg_id"], name: "index_tasks_on_bsg_id", unique: true
    t.index ["given_by"], name: "index_tasks_on_given_by"
    t.index ["name"], name: "index_tasks_on_name", unique: true
  end

  create_table "traders", force: :cascade do |t|
    t.string "bsg_id", null: false
    t.string "name", null: false
    t.string "normalized_name", null: false
    t.string "image_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "buyables", default: [], null: false
    t.jsonb "barteables", default: [], null: false
    t.index ["bsg_id"], name: "index_traders_on_bsg_id", unique: true
    t.index ["normalized_name"], name: "index_traders_on_normalized_name", unique: true
  end
end
