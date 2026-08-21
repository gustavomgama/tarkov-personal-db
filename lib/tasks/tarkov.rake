namespace :tarkov do
  SYNCERS = {
    "items" => "Tarkov::Syncers::ItemSyncer",
    "traders" => "Tarkov::Syncers::TraderSyncer",
    "tasks" => "Tarkov::Syncers::TaskSyncer",
    "barters" => "Tarkov::Syncers::TraderItemSyncer",
    "hideout" => "Tarkov::Syncers::HideoutSyncer",
    "crafts" => "Tarkov::Syncers::HideoutCraftSyncer",
    "fandom_names" => "Tarkov::Syncers::FandomNameSyncer",
    "fandom_enrichment" => "Tarkov::Syncers::FandomEnrichmentSyncer",
    "item_backfill" => "Tarkov::Syncers::ItemBackfillSyncer"
  }.freeze

  desc "Sync all reference data (skips unless the wiki Changelog shows a new game version; FORCE=1 overrides)"
  task sync: :environment do
    live_version = fandom_client.latest_game_version
    last_version = SyncState.last_synced_version

    if last_version == live_version && ENV["FORCE"].blank?
      puts "Game version #{live_version} already synced - skipping (FORCE=1 to override)"
      next
    end

    puts "Syncing game version #{live_version}#{last_version ? " (was #{last_version})" : ""}..."
    syncer.call
    SyncState.record_sync!(live_version)
    puts "Done: synced up to game version #{live_version}"
  rescue Tarkov::Fandom::Client::Error => e
    abort "Cannot verify current game version, refusing to sync: #{e.message} (FORCE=1 does not bypass this)"
  end

  namespace :sync do
    SYNCERS.each_key do |entity|
      desc "Sync #{entity} (Fandom wiki is authoritative for names; run after entity syncs to restore names)"
      task entity.to_sym => :environment do
        count = SYNCERS.fetch(entity).constantize.new(client: client).call
        puts "#{entity}: #{count} records"
      end
    end
  end

  desc "Show how to obtain an item: rake 'tarkov:unlock[7.62x51mm M80]'"
  task :unlock, [ :item ] => :environment do |_task, args|
    item = find_item(args[:item])
    abort "Item not found: #{args[:item]}" unless item

    puts "Item: #{item.name}"
    entries = Tarkov::UnlockPathResolver.new(item).resolve
    abort "No wiki unlock info recorded for this item." if entries.empty?

    entries.each do |entry|
      print_entry(entry)
    end
  end

  def find_item(query)
    slug = query.to_s.tr(" ", "_")
    Item.where("wiki_link LIKE ?", "%/#{slug}").first ||
      Item.find_by(name: query) ||
      Item.where("name LIKE ?", "%#{query}%").first
  end

  def print_entry(entry)
    puts "- Trader: #{entry.unlock.trader_title}#{entry.unlock.loyalty_level ? " (LL#{entry.unlock.loyalty_level})" : ''}"
    if entry.task
      puts "  Unlocked by task: #{entry.task.name}"
      entry.prerequisites.each do |node|
        indent = "    " + ("  " * (node[:depth] - 1))
        puts "#{indent}<- #{node[:task].name}"
      end
      entry.root_quests.each do |root|
        level = root[:task].min_player_level
        puts "  Entry quest: #{root[:task].name}#{level ? " (requires player level #{level})" : ''}"
      end
      puts "  Total player level needed: #{entry.required_player_level || 'unknown'}"
    else
      puts "  Unlocking task not found locally: #{entry.unlock.unlocking_task_title}"
    end
  end

  desc "Cross-check wiki item unlocks against tarkov.dev barter taskUnlock"
  task crosscheck: :environment do
    checked = 0
    agree = 0
    disagree = []
    only_wiki = 0
    ItemUnlock.where.not(unlocking_task_title: [ nil, "" ]).includes(:item).find_each do |row|
      task = Task.find_by_wiki_title(row.unlocking_task_title)
      only_wiki += 1 and next unless task
      offers = row.item.trader_items.where.not(unlock_task_id: nil)
      next if offers.empty?

      checked += 1
      if offers.any? { |offer| offer.unlock_task_id == task.id }
        agree += 1
      else
        disagree << { item: row.item.name, wiki_says: task.name,
                      dev_says: Task.find_by(id: offers.first.unlock_task_id)&.name }
      end
    end
    puts "checked: #{checked}, agree: #{agree}, wiki-only (no dev claim): #{only_wiki}"
    puts "disagreements: #{disagree.size}"
    disagree.first(10).each { |d| puts "  #{d[:item]}: wiki=#{d[:wiki_says]} | dev=#{d[:dev_says]}" }
  end

  desc "Data sanity checks: counts and dangling references"
  task sanity: :environment do
    counts = {
      items: Item.count, traders: Trader.count, tasks: Task.count,
      trader_items: TraderItem.count, task_objectives: TaskObjective.count,
      item_unlocks: ItemUnlock.count, task_requirements: TaskRequirement.count,
      hideout_stations: HideoutStation.count, hideout_levels: HideoutLevel.count,
      last_synced_version: SyncState.last_synced_version
    }
    counts.each { |label, value| puts format("%-22s %s", "#{label}:", value) }

    nameless = Item.where("name LIKE ? OR name LIKE ? OR name = ''", "% Name", "% ShortName").count
    unresolved_unlocks = ItemUnlock.where.not(unlocking_task_title: [ nil, "" ])
                                   .filter_map { |row| row.unlocking_task_title }
                                   .reject { |title| Task.find_by_wiki_title(title) }.size
    raw_targets = HideoutRequirement.where("target_name GLOB '[0-9a-f]*' AND length(target_name) = 24").count
    tasks_without_trader = Task.where(trader_id: nil).count

    puts "--- warnings ---"
    puts "WARN nameless items (no wiki match): #{nameless}" if nameless.positive?
    puts "WARN item unlocks referencing unknown tasks: #{unresolved_unlocks}" if unresolved_unlocks.positive?
    puts "WARN hideout requirements with unresolved tid targets: #{raw_targets}" if raw_targets.positive?
    puts "WARN tasks without trader: #{tasks_without_trader}" if tasks_without_trader.positive?
    puts "OK" if [ nameless, unresolved_unlocks, raw_targets ].all?(&:zero?)
  end

  desc "Show quest chain: rake 'tarkov:chain[Wet Job - Part 1]'"
  task :chain, [ :name ] => :environment do |_task, args|
    quest = Task.find_by_wiki_title(args[:name]) || Task.find_by(name: args[:name]) ||
            Task.where("name LIKE ?", "%#{args[:name]}%").first
    abort "Task not found: #{args[:name]}" unless quest

    view = Tarkov::TaskChainView.new(quest).call
    puts "Task: #{view[:task].name}"
    puts "Requires:"
    view[:requires].each { |node| puts "  #{'  ' * (node[:depth] - 1)}<- #{node[:task].name}" }
    puts "(none)" if view[:requires].empty?
    puts "Leads to:"
    view[:leads_to].each { |node| puts "  #{'  ' * (node[:depth] - 1)}-> #{node[:task].name}" }
    puts "(none)" if view[:leads_to].empty?
  end

  def client
    Tarkov::Client.new(game_mode: ENV.fetch("GAME_MODE", "regular"), lang: ENV.fetch("TARKOV_LANG", "en"))
  end

  def fandom_client
    @fandom_client ||= Tarkov::Fandom::Client.new
  end

  def syncer
    Tarkov::Syncer.new(client: client)
  end
end
