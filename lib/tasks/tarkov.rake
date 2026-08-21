namespace :tarkov do
  SYNCERS = {
    "items" => "Tarkov::Syncers::ItemSyncer",
    "traders" => "Tarkov::Syncers::TraderSyncer",
    "tasks" => "Tarkov::Syncers::TaskSyncer",
    "barters" => "Tarkov::Syncers::TraderItemSyncer",
    "hideout" => "Tarkov::Syncers::HideoutSyncer"
  }.freeze

  desc "Sync all reference data from json.tarkov.dev (GAME_MODE=regular|pve, TARKOV_LANG=en)"
  task sync: :environment do
    results = syncer.call
    results.each { |entity, count| puts "#{entity}: #{count} records" }
  end

  namespace :sync do
    SYNCERS.each_key do |entity|
      desc "Sync #{entity} from json.tarkov.dev (GAME_MODE=regular|pve, TARKOV_LANG=en)"
      task entity.to_sym => :environment do
        count = SYNCERS.fetch(entity).constantize.new(client: client).call
        puts "#{entity}: #{count} records"
      end
    end
  end

  def client
    Tarkov::Client.new(game_mode: ENV.fetch("GAME_MODE", "regular"), lang: ENV.fetch("TARKOV_LANG", "en"))
  end

  def syncer
    Tarkov::Syncer.new(client: client)
  end
end
