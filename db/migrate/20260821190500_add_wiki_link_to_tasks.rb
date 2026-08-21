class AddWikiLinkToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :wiki_link, :string
  end
end
