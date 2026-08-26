namespace :tarkov do
  desc "Full disaster recovery: recreate schema, re-sync all data from tarkov.dev and re-download images"
  task restore: :environment do
    Rake::Task["db:prepare"].invoke
    ENV["FORCE"] = "1"
    Rake::Task["tarkov:sync"].invoke
    Rake::Task["tarkov:images"].invoke
    Rake::Task["tarkov:sanity"].invoke
  end

  SYNCERS = {
    "items" => "Tarkov::Syncers::ItemSyncer",
    "traders" => "Tarkov::Syncers::TraderSyncer",
    "tasks" => "Tarkov::Syncers::TaskSyncer",
    "barters" => "Tarkov::Syncers::BarterSyncer"
  }.freeze

  desc "Sync all reference data (skips unless the wiki Changelog shows a new game version; FORCE=1 overrides)"
  task sync: :environment do
    live_version = current_version
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
      desc "Sync #{entity} (manual repair tool; names resolve from json.tarkov.dev localization files)"
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
    abort "No acquisition routes recorded for this item." if entries.empty?

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
    trader = entry.unlock.trader_name || entry.unlock.trader&.name
    puts "- Trader: #{trader}#{entry.unlock.loyalty_level ? " (LL#{entry.unlock.loyalty_level})" : ''}"
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
      puts "  Unlocking task not found locally (unlock row has no task reference)"
    end
  end

  desc "Verify local data against the Fandom wiki (report-only, writes log/factcheck-<version>.md)"
  task factcheck: :environment do
    Tarkov::FactChecker.new.call
  end

  desc "Data sanity checks: counts and dangling references"
  task sanity: :environment do
    counts = {
      items: Item.count, traders: Trader.count, tasks: Task.count,
      item_unlocks: ItemUnlock.count, task_requirements: TaskRequirement.count,
      last_synced_version: SyncState.last_synced_version
    }
    counts.each { |label, value| puts format("%-22s %s", "#{label}:", value) }

    nameless = Item.where("name LIKE ? OR name LIKE ? OR name = ''", "% Name", "% ShortName").count
    dangling_unlock_tasks = ItemUnlock.where.not(task_id: nil)
                                      .where("task_id NOT IN (SELECT id FROM tasks)").count
    tasks_without_trader = Task.where(trader_id: nil).count

    puts "--- warnings ---"
    puts "WARN nameless items (placeholder names): #{nameless}" if nameless.positive?
    puts "WARN unlock rows referencing deleted tasks: #{dangling_unlock_tasks}" if dangling_unlock_tasks.positive?
    puts "WARN tasks without trader: #{tasks_without_trader}" if tasks_without_trader.positive?
    puts "OK" if [ nameless, dangling_unlock_tasks, tasks_without_trader ].all?(&:zero?)
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

  # Wiki version check when reachable; otherwise fall back to the local
  # refjsons/ snapshots so syncs work fully offline.
  def current_version
    fandom_client.latest_game_version
  rescue Tarkov::Fandom::Client::Error => e
    raise e unless Tarkov::Client::REFJSONS_DIR.join("items.json").exist?

    puts "Wiki unreachable (#{e.message}); using refjsons snapshots"
    "refjsons-#{File.mtime(Tarkov::Client::REFJSONS_DIR.join('items.json')).to_i}"
  end

  def fandom_client
    @fandom_client ||= Tarkov::Fandom::Client.new
  end

  def syncer
    Tarkov::Syncer.new(client: client)
  end

  # ---- offline assets & schema additions that predate a full resync ----

  desc "Backfill slugs, barter ingredients and container categories from json.tarkov.dev (no full resync)"
  task backfill: :environment do
    c = client
    names = c.localizations
    items_payload = c.items.fetch("items", {})
    deriver = Tarkov::CategoryDeriver.new(items_payload.values.group_by { |a| a["normalizedName"].to_s })

    items_payload.each_value do |attrs|
      item = Item.find_by(tid: attrs["id"])
      next unless item

      item.update_columns(
        slug: attrs["normalizedName"],
        name: names.item_name(attrs["id"]) || attrs["name"],
        categories: deriver.derive(attrs)
      )
    end

    c.tasks.fetch("tasks", {}).each_value do |attrs|
      Task.find_by(tid: attrs["id"])&.update_column(:slug, attrs["normalizedName"])
    end

    c.traders.each_value do |attrs|
      Trader.find_by(tid: attrs["id"])&.update_column(:slug, attrs["normalizedName"])
    end

    count = Tarkov::Syncers::BarterSyncer.new(client: c).call
    puts "Backfilled slugs/categories; barters: #{count} rows"
  rescue Tarkov::Client::Error => e
    abort "Backfill failed: #{e.message}"
  end

  desc "Download every item/trader image into public/images so the app runs fully offline"
  task images: :environment do
    require "uri"

    targets = []
    Item.find_each do |item|
      targets << [ "items", item.tid, "-icon", item.icon_link ]
      targets << [ "items", item.tid, "", item.image_link || item.icon_link ]
    end
    Trader.find_each { |trader| targets << [ "traders", trader.tid, "", trader.image_url ] }
    # Barter-only ingredients are absent from the items payload but the asset
    # CDN still serves their icons by bare tid.
    ItemUnlock.of_type("barter").pluck(:required_items).each do |ingredients|
      Array(ingredients).each do |ingredient|
        next unless ingredient["tid"]

        targets << [ "items", ingredient["tid"], "-icon",
                     "https://assets.tarkov.dev/#{ingredient["tid"]}-icon.webp" ]
      end
    end

    connection = Faraday.new { |conn| conn.adapter Faraday.default_adapter }
    ok = skipped = failed = 0

    targets.each do |kind, tid, suffix, url|
      next if url.blank?

      dir = Rails.root.join("public/images/#{kind}")
      next skipped += 1 unless Dir[dir.join("#{tid}#{suffix}.*")].empty?

      begin
        ext = File.extname(URI.parse(url).path).presence || ".png"
        response = connection.get(url)
        raise Tarkov::Client::Error, "status #{response.status}" unless response.success?

        dir.mkpath
        File.binwrite(dir.join("#{tid}#{suffix}#{ext}"), response.body)
        ok += 1
        print "." if (ok % 100).zero?
      rescue StandardError => e
        warn "\nFAIL #{url}: #{e.message}"
        failed += 1
      end
    end
    puts "\nimages: #{ok} downloaded, #{skipped} already present, #{failed} failed"
  end
end
