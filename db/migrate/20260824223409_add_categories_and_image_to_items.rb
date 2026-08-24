class AddCategoriesAndImageToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :categories, :text
    add_column :items, :image_link, :string
  end
end
