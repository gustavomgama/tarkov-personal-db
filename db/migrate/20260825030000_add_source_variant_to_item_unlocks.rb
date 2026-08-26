class AddSourceVariantToItemUnlocks < ActiveRecord::Migration[8.1]
  def change
    add_column :item_unlocks, :source_variant, :string
  end
end
