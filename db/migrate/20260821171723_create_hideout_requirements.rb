class CreateHideoutRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :hideout_requirements do |t|
      t.references :hideout_level, null: false, foreign_key: true
      t.string :requirement_type, null: false # station | trader | skill
      t.string :target_name, null: false
      t.integer :level
      t.timestamps

      t.index %i[hideout_level_id requirement_type target_name], unique: true
    end
  end
end
