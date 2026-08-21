class CreateHideoutLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :hideout_levels do |t|
      t.references :hideout_station, null: false, foreign_key: true
      t.integer :level, null: false
      t.integer :construction_time
      t.text :description
      t.timestamps

      t.index %i[hideout_station_id level], unique: true
    end
  end
end
