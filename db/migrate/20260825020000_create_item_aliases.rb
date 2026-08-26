class CreateItemAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :item_aliases do |t|
      t.string "tid", null: false
      t.string "canonical_tid", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "tid" ], name: "index_item_aliases_on_tid", unique: true
    end
  end
end
