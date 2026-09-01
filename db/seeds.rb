# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

SEED_TASKS = %w[Collector].freeze

tasks_index = JSON.parse(File.read(Rails.root.join("offlinedata/tarkovunlockables/tasks_index.json")))
by_name = tasks_index.index_by { |t| t["full_name"] }

SEED_TASKS.each do |full_name|
  doc = by_name[full_name]
  next unless doc

  Task.find_or_create_by!(name: doc["name"]) do |t|
    t.bsg_id = doc["id"]
    t.full_name = doc["full_name"]
    t.wiki_link = doc["wiki_link"]
    t.given_by = doc["given_by"]
    t.kappa_required = doc["kappa_required"]
    t.lightkeeper_required = doc["lightkeeper_required"]
    t.leads_to = doc["leads_to"]
    t.requirements = doc["requirements"]
    t.start_rewards = doc["start_rewards"]
    t.finish_rewards = doc["finish_rewards"]
  end
end
