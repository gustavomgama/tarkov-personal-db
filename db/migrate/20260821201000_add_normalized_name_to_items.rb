class AddNormalizedNameToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :normalized_name, :string
    add_index :items, :normalized_name
  end
end
