class AddImageUrlToTraders < ActiveRecord::Migration[8.1]
  def change
    add_column :traders, :image_url, :string
  end
end
