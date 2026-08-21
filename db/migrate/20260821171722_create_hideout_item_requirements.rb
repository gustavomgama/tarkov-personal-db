class CreateHideoutItemRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :hideout_item_requirements do |t|
      t.references :hideout_level, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :count
      t.timestamps

      t.index %i[hideout_level_id item_id], unique: true
    end
  end
end
