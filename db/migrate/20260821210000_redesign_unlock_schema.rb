class RedesignUnlockSchema < ActiveRecord::Migration[8.1]
  CURRENCY_ITEM_TIDS = %w[
    5449016a4bdc2d6f028b456f
    569668774bdc2da2298b4568
    56966ab6190c7dc22710c2b5
  ].freeze

  def change
    drop_table :trader_items

    drop_table :item_unlocks do |t|
      t.timestamps
    end

    create_table :item_unlocks do |t|
      t.string :item_name, null: false
      t.references :item, null: false, foreign_key: true
      t.references :trader, foreign_key: true
      t.string :trader_name
      t.integer :loyalty_level
      t.text :unlock_types, default: "[]", null: false
      t.references :task, foreign_key: { to_table: :tasks }

      t.timestamps

      t.index %i[item_id task_id], name: "index_item_unlocks_item_task"
    end

    change_table :items do |t|
      t.remove :description, :short_name, :types, :width, :height, :weight,
               :normalized_name, :unlock_text
      t.decimal :price, precision: 14, scale: 2
      t.string :currency
      t.boolean :craft, default: false, null: false
      t.boolean :barter, default: false, null: false
      t.boolean :require_unlock, default: false, null: false
    end

    change_table :tasks do |t|
      t.remove :description, :faction_name
      t.integer :previous_task_id
      t.string :previous_task_name
      t.integer :next_task_id
      t.string :next_task_name
    end

    create_table :task_rewards do |t|
      t.references :task, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :count
      t.timestamps

      t.index %i[task_id item_id], unique: true
    end

    change_table :traders do |t|
      t.remove :description, :currency, :normalized_name
    end
  end
end
