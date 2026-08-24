class AddSourceToItemUnlocks < ActiveRecord::Migration[8.1]
  def change
    add_column :item_unlocks, :source, :string, default: "wiki", null: false
  end
end
