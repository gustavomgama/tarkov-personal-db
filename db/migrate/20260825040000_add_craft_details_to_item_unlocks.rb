class AddCraftDetailsToItemUnlocks < ActiveRecord::Migration[8.1]
  def change
    add_column :item_unlocks, :station, :string
    add_column :item_unlocks, :station_level, :integer
  end
end
