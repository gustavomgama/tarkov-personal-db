class CreateAllTables < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :bsg_id
      t.string :slug
      t.string :full_name
      t.string :short_name
      t.text :categories, array: true, default: []
      t.text :links, array: true, default: []
      t.text :images, array: true, default: []
    end

    create_table :properties do |t|
      t.references :item, foreign_key: { to_table: :items }
      t.string :properties_type
      t.text :allowed_ammo, array: true, default: []
      t.string :ammo_type
      t.text :armor_slots, array: true, default: []
      t.string :armor_type
      t.string :base_item
      t.string :caliber
      t.integer :armor_class
      t.integer :damage
      t.boolean :default
      t.string :default_ammo
      t.string :default_preset
      t.integer :penetration_power
      t.text :presets, array: true, default: []
      t.integer :slash_damage
      t.integer :stab_damage
      t.string :category
      t.text :zones, array: true, default: []
    end

    create_table :slots do |t|
      t.references :property, foreign_key: { to_table: :properties }
      t.string :name_id
      t.boolean :required
      t.text :allowed_items, array: true, default: []
    end

    create_table :item_task_rewards do |t|
      t.references :item, foreign_key: { to_table: :items }
      t.string :task_id
      t.string :task_name
      t.string :reward_type
    end

    create_table :item_hideouts do |t|
      t.references :item, foreign_key: { to_table: :items }
      t.string :station_name
      t.integer :station_level
      t.integer :quantity
    end

    create_table :item_barters do |t|
      t.references :item, foreign_key: { to_table: :items }
      t.string :trader_name
      t.string :trader_level
    end

    create_table :item_currencies do |t|
      t.references :item, foreign_key: { to_table: :items }
      t.string :trader_name
      t.string :trader_level
      t.string :currency
    end

    create_table :tasks do |t|
      t.string :bsg_id
      t.string :full_name
      t.string :name
      t.string :wiki_link
      t.string :given_by
      t.boolean :kappa_required
      t.boolean :lightkeeper_required
    end

    create_table :leads_tos do |t|
      t.references :task, foreign_key: { to_table: :tasks }
      t.string :follow_up_task_id
      t.string :follow_up_task_name
    end

    create_table :requirements do |t|
      t.references :task, foreign_key: { to_table: :tasks }
      t.integer :player_level
    end

    create_table :previous_tasks do |t|
      t.references :requirement, foreign_key: { to_table: :requirements }
      t.string :task_id
      t.string :task_name
    end

    create_table :rewards do |t|
      t.references :task, foreign_key: { to_table: :tasks }
      t.string :reward_type
    end

    create_table :loose_items do |t|
      t.references :reward, foreign_key: { to_table: :rewards }
      t.string :item_id
      t.string :item_name
      t.integer :count
    end

    create_table :offer_unlocks do |t|
      t.references :reward, foreign_key: { to_table: :rewards }
      t.string :item_id
      t.string :item_name
      t.string :trader_name
      t.string :trader_level
    end

    create_table :barter_unlocks do |t|
      t.references :reward, foreign_key: { to_table: :rewards }
      t.string :item_id
      t.string :item_name
    end

    create_table :barter_requirements do |t|
      t.references :barter_unlock, foreign_key: { to_table: :barter_unlocks }
      t.string :trader_name
      t.string :trader_level
    end

    create_table :barter_requirement_items do |t|
      t.references :barter_requirement, foreign_key: { to_table: :barter_requirements }
      t.string :item_id
      t.string :item_name
      t.integer :count
    end

    create_table :barter_results do |t|
      t.references :barter_unlock, foreign_key: { to_table: :barter_unlocks }
    end

    create_table :barter_result_items do |t|
      t.references :barter_result, foreign_key: { to_table: :barter_results }
      t.string :item_id
      t.string :item_name
    end

    create_table :craft_unlocks do |t|
      t.references :reward, foreign_key: { to_table: :rewards }
      t.string :item_id
      t.string :item_name
      t.string :hideout_station
      t.integer :station_level
    end

    create_table :craft_requirements do |t|
      t.references :craft_unlock, foreign_key: { to_table: :craft_unlocks }
      t.string :trader_name
      t.string :trader_level
    end

    create_table :craft_requirement_items do |t|
      t.references :craft_requirement, foreign_key: { to_table: :craft_requirements }
      t.string :item_id
      t.string :item_name
      t.integer :count
    end

    create_table :craft_results do |t|
      t.references :craft_unlock, foreign_key: { to_table: :craft_unlocks }
    end

    create_table :craft_result_items do |t|
      t.references :craft_result, foreign_key: { to_table: :craft_results }
      t.string :item_id
      t.string :item_name
    end
  end
end
