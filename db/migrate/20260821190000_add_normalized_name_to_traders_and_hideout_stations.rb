class AddNormalizedNameToTradersAndHideoutStations < ActiveRecord::Migration[8.1]
  def change
    add_column :traders, :normalized_name, :string
    add_index :traders, :normalized_name

    add_column :hideout_stations, :normalized_name, :string
    add_index :hideout_stations, :normalized_name
  end
end
