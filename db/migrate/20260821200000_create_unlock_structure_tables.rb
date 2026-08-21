class CreateUnlockStructureTables < ActiveRecord::Migration[8.1]
  def change
    create_table :task_requirements do |t|
      t.references :task, null: false, foreign_key: true
      t.references :required_task, null: false, foreign_key: { to_table: :tasks }
      t.timestamps

      t.index %i[task_id required_task_id], unique: true
    end

    create_table :trader_loyalty_levels do |t|
      t.references :trader, null: false, foreign_key: true
      t.integer :level, null: false
      t.integer :required_player_level
      t.decimal :required_reputation, precision: 8, scale: 2
      t.timestamps

      t.index %i[trader_id level], unique: true
    end

    create_table :item_unlocks do |t|
      t.references :item, null: false, foreign_key: true
      t.string :trader_title, null: false
      t.integer :loyalty_level
      t.string :unlocking_task_title
      t.timestamps

      t.index %i[item_id trader_title], unique: true
    end
  end
end
