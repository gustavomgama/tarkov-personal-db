module Tarkov
  class Syncer
    STEPS = {
      items: "Tarkov::Syncers::ItemSyncer",
      traders: "Tarkov::Syncers::TraderSyncer",
      tasks: "Tarkov::Syncers::TaskSyncer",
      task_chains: "Tarkov::Syncers::TaskChainSyncer",
      barters: "Tarkov::Syncers::BarterSyncer",
      trader_purge: "Tarkov::Syncers::TraderPurge",
      refresh_names: "Tarkov::Syncers::DenormalizedNamesRefresh"
    }.freeze

    def initialize(client: Tarkov::Client.new, logger: Rails.logger)
      @client = client
      @logger = logger
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

    attr_reader :logger

    def build_syncer(klass)
      klass.constantize.new(client: @client)
    end

    def log(message)
      logger.info("[tarkov:sync] #{message}")
    end
  end
end
