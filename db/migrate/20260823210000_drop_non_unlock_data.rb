class DropNonUnlockData < ActiveRecord::Migration[8.1]
  def change
    drop_table :task_objectives
    drop_table :task_rewards
    drop_table :craft_items
    drop_table :hideout_crafts
    drop_table :hideout_item_requirements
    drop_table :hideout_requirements
    drop_table :hideout_levels
    drop_table :hideout_stations

    remove_column :items, :quest_item
    remove_column :items, :grid_image_link
  end
end
