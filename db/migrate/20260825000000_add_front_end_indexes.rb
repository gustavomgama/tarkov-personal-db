class AddFrontEndIndexes < ActiveRecord::Migration[8.1]
  def change
    # Support the index-page sorts and searches.
    add_index :items, "LOWER(name)", name: "index_items_on_lower_name"
    add_index :items, :price
    add_index :items, :currency
    add_index :tasks, "LOWER(name)", name: "index_tasks_on_lower_name"
    add_index :tasks, :min_player_level
  end
end
