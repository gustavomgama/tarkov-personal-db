class AddCompatToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :compat, :text, default: "{}", null: false
  end
end
