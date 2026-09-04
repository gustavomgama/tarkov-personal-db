Trader.delete_all
Task.delete_all
Item.delete_all

puts "Loading JSON data..."
buyables_data = JSON.parse(File.read(Rails.root.join('offlinedata/tarkovunlockables/buyables_index.json')))
barteables_data = JSON.parse(File.read(Rails.root.join('offlinedata/tarkovunlockables/barteables_index.json')))
craftables_data = JSON.parse(File.read(Rails.root.join('offlinedata/tarkovunlockables/craftables_index.json')))

puts "Creating traders..."
traders = {}
traders_json = JSON.parse(File.read(Rails.root.join('offlinedata/tarkovunlockables/traders_index.json')))
traders_json['traders'].each do |_key, trader_json|
  trader = Trader.create!(
    bsg_id: trader_json['id'],
    name: trader_json['name'],
    normalized_name: trader_json['normalizedName'],
    image_link: trader_json['imageLink']
  )
  traders[trader.normalized_name] = trader
end
puts "Created #{Trader.count} traders"

puts "Creating tasks..."
tasks = JSON.parse(File.read(Rails.root.join('offlinedata/tarkovunlockables/tasks_index.json')))
tasks.each do |task_json|
  next if task_json['bsg_id'].blank? || task_json['name'].blank?
  Task.create!(
    bsg_id: task_json['bsg_id'],
    name: task_json['name'],
    full_name: task_json['full_name'],
    wiki_link: task_json['wiki_link'],
    given_by: task_json['given_by'],
    kappa_required: task_json['kappa_required'],
    lightkeeper_required: task_json['lightkeeper_required'],
    leads_to: task_json['leads_to'],
    requirements: task_json['requirements'],
    start_rewards: task_json['start_rewards'],
    finish_rewards: task_json['finish_rewards']
  )
rescue ActiveRecord::RecordInvalid => e
  puts "Skipping task #{task_json['full_name']}: #{e.message}"
end
puts "Created #{Task.count} tasks"

puts "Creating items with buyables/barteables/craftables..."
items_json = JSON.parse(File.read(Rails.root.join('offlinedata/tarkovunlockables/items_index.json')))

items_json.each do |item_json|
  bsg_id = item_json['id']
  full_name = item_json['fullName']

  item_buyables = buyables_data.select { |b| b['item_id'] == bsg_id }
  item_barteables = barteables_data.select do |b|
    b.dig('result', 0, 'items', 0, 'id') == bsg_id
  end
  item_craftables = []
  craftables_data.each do |_station, crafts|
    crafts.each do |craft|
      if craft.dig('output_items', 0, 'name') == full_name
        item_craftables << craft
      end
    end
  end

  Item.create!(
    bsg_id: bsg_id,
    slug: item_json['slug'],
    full_name: full_name,
    short_name: item_json['shortName'],
    types: item_json['types'],
    links: item_json['links'],
    images: item_json['images'],
    properties: item_json['properties'],
    conflicting_items: item_json['conflictingItems'],
    conflicting_slot_ids: item_json['conflictingSlotIds'],
    conflicting_categories: item_json['conflictingCategories'],
    obtain_from: item_json['obtain_from'],
    buyables: item_buyables,
    barteables: item_barteables,
    craftables: item_craftables
  )
end
puts "Created #{Item.count} items"

puts "Populating trader buyables and barteables..."
Trader.find_each do |trader|
  trader_buyables = buyables_data.select { |b| b['trader_name'] == trader.normalized_name }
  trader_barteables = barteables_data.select do |b|
    b.dig('requirements', 0, 'trader_name') == trader.normalized_name
  end
  trader.update!(buyables: trader_buyables, barteables: trader_barteables)
end
puts "Done populating trader unlockables"

puts "Created #{Trader.count} traders, #{Task.count} tasks, #{Item.count} items"
