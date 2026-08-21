class CreateTraders < ActiveRecord::Migration[8.1]
  def change
    create_table :traders do |t|
      t.string :tid, null: false
      t.string :name, null: false
      t.text :description
      t.datetime :reset_time
      t.string :currency, null: false, default: "RUB"
      t.timestamps

      t.index :tid, unique: true
    end
  end
end
