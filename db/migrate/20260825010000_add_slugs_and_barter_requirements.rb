class AddSlugsAndBarterRequirements < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :slug, :string
    add_column :tasks, :slug, :string
    add_column :traders, :slug, :string
    add_index :items, :slug
    add_index :tasks, :slug

    add_column :item_unlocks, :required_items, :json, default: {}, null: false
  end
end
