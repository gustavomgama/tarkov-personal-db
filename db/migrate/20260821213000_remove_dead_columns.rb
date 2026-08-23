class RemoveDeadColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :tasks, :previous_task_title
    remove_column :items, :category
  end
end
