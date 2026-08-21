class AddTaskFlagsAndQuestItemSupport < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :lightkeeper_required, :boolean, default: false, null: false
    add_column :tasks, :faction_name, :string
  end
end
