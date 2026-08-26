class AddBallisticsColumnsToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :penetration_power, :integer
    add_column :items, :armor_class, :integer
  end
end
