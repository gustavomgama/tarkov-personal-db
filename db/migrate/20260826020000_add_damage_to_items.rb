class AddDamageToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :damage, :integer
  end
end
