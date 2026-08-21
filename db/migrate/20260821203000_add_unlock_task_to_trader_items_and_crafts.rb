class AddUnlockTaskToTraderItemsAndCrafts < ActiveRecord::Migration[8.1]
  def change
    add_reference :trader_items, :unlock_task, foreign_key: { to_table: :tasks }

    create_table :hideout_crafts do |t|
      t.string :tid, null: false
      t.references :hideout_station, null: false, foreign_key: true
      t.integer :level
      t.integer :duration
      t.timestamps

      t.index :tid, unique: true
    end

    create_table :craft_items do |t|
      t.references :hideout_craft, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :count
      t.timestamps

      t.index %i[hideout_craft_id item_id kind], unique: true, name: "index_craft_items_uniqueness"
    end
  end
end
