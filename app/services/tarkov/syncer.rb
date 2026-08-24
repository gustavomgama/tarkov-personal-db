module Tarkov
  class Syncer
    STEPS = {
      items: "Tarkov::Syncers::ItemSyncer",
      traders: "Tarkov::Syncers::TraderSyncer",
      tasks: "Tarkov::Syncers::TaskSyncer",
      task_chains: "Tarkov::Syncers::TaskChainSyncer",
      barters: "Tarkov::Syncers::BarterSyncer",
      crafts: "Tarkov::Syncers::CraftSyncer",
      trader_purge: "Tarkov::Syncers::TraderPurge",
      junk_purge: "Tarkov::Syncers::ItemPurge",
      refresh_names: "Tarkov::Syncers::DenormalizedNamesRefresh"
    }.freeze

    FANDOM_STEP = "Tarkov::Syncers::TaskChainSyncer"

    def initialize(client: Tarkov::Client.new, logger: Rails.logger, fandom_client: nil)
      @client = client
      @logger = logger
      @fandom_client = fandom_client
    end

    def call
      ActiveRecord::Base.transaction do
        STEPS.each_with_object({}) do |(step, klass), results|
          log "syncing #{step}..."
          results[step] = build_syncer(klass).call
          log "#{step}: #{results[step]} records"
        end
      end
    end

    private

    attr_reader :logger, :fandom_client

    def build_syncer(klass)
      args = { client: @client }
      if klass == FANDOM_STEP && fandom_client
        args[:fandom_client] = fandom_client
      end
      klass.constantize.new(**args)
    end

    def log(message)
      logger.info("[tarkov:sync] #{message}")
    end
  end
end
