class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :tid, null: false
      t.string :name, null: false
      t.references :trader, foreign_key: true
      t.integer :min_player_level
      t.boolean :kappa_required, default: false
      t.timestamps

      t.index :tid, unique: true
    end
  end
end
