class AddCurrencyAndRefGp < ActiveRecord::Migration[8.1]
  def change
    add_column :item_unlocks, :currency, :string
    add_column :items, :ref_gp, :boolean, default: false, null: false
    add_index :items, :ref_gp
  end
end
