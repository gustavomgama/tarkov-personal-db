class RevertItemPriceToDecimal < ActiveRecord::Migration[8.1]
  def up
    change_column :items, :price, :decimal, precision: 14, scale: 2
  end

  def down
    change_column :items, :price, :integer
  end
end
