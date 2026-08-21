class CreateSyncStates < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_states do |t|
      t.string :version, null: false
      t.datetime :synced_at, null: false

      t.timestamps
    end
  end
end
