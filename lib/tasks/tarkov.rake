namespace :tarkov do
  SYNCERS = {
    "items" => "Tarkov::Syncers::ItemSyncer",
    "traders" => "Tarkov::Syncers::TraderSyncer",
    "tasks" => "Tarkov::Syncers::TaskSyncer",
    "barters" => "Tarkov::Syncers::TraderItemSyncer",
    "hideout" => "Tarkov::Syncers::HideoutSyncer",
    "fandom_names" => "Tarkov::Syncers::FandomNameSyncer",
    "fandom_enrichment" => "Tarkov::Syncers::FandomEnrichmentSyncer"
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
