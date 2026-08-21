class CreateTaskObjectives < ActiveRecord::Migration[8.1]
  def change
    create_table :task_objectives do |t|
      t.references :task, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :count
      t.boolean :found_in_raid, default: false
      t.timestamps

      t.index %i[task_id item_id], unique: true
    end
  end
end
