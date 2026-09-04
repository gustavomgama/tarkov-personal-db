class AddUnlockablesToItemsAndTraders < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :buyables, :jsonb, default: [], null: false
    add_column :items, :barteables, :jsonb, default: [], null: false
    add_column :items, :craftables, :jsonb, default: [], null: false
    add_column :traders, :buyables, :jsonb, default: [], null: false
    add_column :traders, :barteables, :jsonb, default: [], null: false
  end
end
