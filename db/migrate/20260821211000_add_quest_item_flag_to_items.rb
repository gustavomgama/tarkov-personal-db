class AddQuestItemFlagToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :quest_item, :boolean, default: false, null: false
  end
end
