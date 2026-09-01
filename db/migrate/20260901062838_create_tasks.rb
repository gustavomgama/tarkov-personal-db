class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :bsg_id, null: false, default: ""
      t.string :full_name, null: false
      t.string :name, null: false, default: ""
      t.string :wiki_link, null: false, default: ""
      t.string :given_by, null: false

      t.boolean :kappa_required, null: false, default: false
      t.boolean :lightkeeper_required, null: false, default: false

      # [{ "task_id": "...", "task_name": "..." }]
      t.jsonb :leads_to, null: false, default: []

      # [{ "player_level": 0, "trader_level": [...], "previous_tasks": [...] }]
      t.jsonb :requirements, null: false, default: []

      # [{ "loose_items": [...], "offer_unlocks": [...],
      #    "barter_unlocks": [...], "craft_unlocks": [...] }]
      t.jsonb :start_rewards, null: false, default: []
      t.jsonb :finish_rewards, null: false, default: []

      t.timestamps
    end

    add_index :tasks, :bsg_id, unique: true, where: "bsg_id <> ''"
    add_index :tasks, :name, unique: true, where: "name <> ''"
    add_index :tasks, :given_by
    add_index :tasks, :kappa_required
    add_index :tasks, :lightkeeper_required
    add_index :tasks, :full_name
  end
end
