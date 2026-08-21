class CreateTraderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :trader_items do |t|
      t.references :trader, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :min_trader_level
      t.decimal :price, precision: 10, scale: 2
      t.string :currency, null: false, default: "RUB"
      t.boolean :barter, null: false, default: false
      t.timestamps

      t.index %i[trader_id item_id], unique: true
    end
  end
end
