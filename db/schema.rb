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

ActiveRecord::Schema[8.1].define(version: 2026_09_01_062838) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "tasks", force: :cascade do |t|
    t.string "bsg_id", default: "", null: false
    t.string "full_name", null: false
    t.string "name", default: "", null: false
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
    t.index ["bsg_id"], name: "index_tasks_on_bsg_id", unique: true, where: "((bsg_id)::text <> ''::text)"
    t.index ["full_name"], name: "index_tasks_on_full_name"
    t.index ["given_by"], name: "index_tasks_on_given_by"
    t.index ["kappa_required"], name: "index_tasks_on_kappa_required"
    t.index ["lightkeeper_required"], name: "index_tasks_on_lightkeeper_required"
    t.index ["name"], name: "index_tasks_on_name", unique: true, where: "((name)::text <> ''::text)"
  end
end
