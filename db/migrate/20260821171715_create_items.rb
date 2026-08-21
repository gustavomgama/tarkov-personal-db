class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :tid, null: false
      t.string :name, null: false
      t.string :short_name
      t.text :description
      t.string :category
      t.text :types, default: "[]"
      t.integer :width
      t.integer :height
      t.decimal :weight, precision: 8, scale: 3
      t.string :icon_link
      t.string :grid_image_link
      t.string :wiki_link
      t.timestamps

      t.index :tid, unique: true
    end
  end
end
