class CreateHideoutStations < ActiveRecord::Migration[8.1]
  def change
    create_table :hideout_stations do |t|
      t.string :tid, null: false
      t.string :name, null: false
      t.timestamps

      t.index :tid, unique: true
    end
  end
end
