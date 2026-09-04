class CreateTradersItemsTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :traders do |t|
      t.string :bsg_id, null: false
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.string :image_link

      t.timestamps
    end
    add_index :traders, :bsg_id, unique: true
    add_index :traders, :normalized_name, unique: true

    create_table :tasks do |t|
      t.string :bsg_id, null: false
      t.string :name, null: false
      t.string :full_name, null: false
      t.string :wiki_link, default: "", null: false
      t.string :given_by, null: false
      t.boolean :kappa_required, default: false, null: false
      t.boolean :lightkeeper_required, default: false, null: false
      t.jsonb :leads_to, default: [], null: false
      t.jsonb :requirements, default: [], null: false
      t.jsonb :start_rewards, default: [], null: false
      t.jsonb :finish_rewards, default: [], null: false

      t.timestamps
    end
    add_index :tasks, :bsg_id, unique: true
    add_index :tasks, :name, unique: true
    add_index :tasks, :given_by

    create_table :items do |t|
      t.string :bsg_id, null: false
      t.string :slug, null: false
      t.string :full_name, null: false
      t.string :short_name
      t.jsonb :types, default: [], null: false
      t.jsonb :links, default: {}, null: false
      t.jsonb :images, default: {}, null: false
      t.jsonb :properties, default: {}, null: false
      t.jsonb :conflicting_items, default: [], null: false
      t.jsonb :conflicting_slot_ids, default: [], null: false
      t.jsonb :conflicting_categories, default: [], null: false
      t.jsonb :obtain_from, default: [], null: false

      t.timestamps
    end
    add_index :items, :bsg_id, unique: true
    add_index :items, :slug, unique: true
  end
end
