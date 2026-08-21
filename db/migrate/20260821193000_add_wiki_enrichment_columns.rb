class AddWikiEnrichmentColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :unlock_text, :string
    add_column :tasks, :description, :text
    add_column :tasks, :previous_task_title, :string
  end
end
