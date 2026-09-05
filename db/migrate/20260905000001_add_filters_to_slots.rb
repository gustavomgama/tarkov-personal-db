class AddFiltersToSlots < ActiveRecord::Migration[8.0]
  def change
    add_column :slots, :allowed_categories, :text, array: true, default: []
    add_column :slots, :excluded_categories, :text, array: true, default: []
    add_column :slots, :excluded_items, :text, array: true, default: []
  end
end
