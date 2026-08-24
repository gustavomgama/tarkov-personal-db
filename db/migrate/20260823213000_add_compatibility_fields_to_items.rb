class AddCompatibilityFieldsToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :caliber, :string
    add_column :items, :gun, :boolean, default: false, null: false
    add_column :items, :ammo, :boolean, default: false, null: false
    add_column :items, :allowed_ammo, :text, default: "[]", null: false
  end
end
