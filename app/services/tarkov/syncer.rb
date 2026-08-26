module Tarkov
  class Syncer
    STEPS = {
      items: "Tarkov::Syncers::ItemSyncer",
      traders: "Tarkov::Syncers::TraderSyncer",
      tasks: "Tarkov::Syncers::TaskSyncer",
      task_chains: "Tarkov::Syncers::TaskChainSyncer",
      barters: "Tarkov::Syncers::BarterSyncer",
      crafts: "Tarkov::Syncers::CraftSyncer",
      historical_purge: "Tarkov::Syncers::HistoricalPurge",
      trader_purge: "Tarkov::Syncers::TraderPurge",
      junk_purge: "Tarkov::Syncers::ItemPurge",
      aliases: "Tarkov::Syncers::AliasHygiene",
      refresh_names: "Tarkov::Syncers::DenormalizedNamesRefresh"
    }.freeze

    FANDOM_STEP = "Tarkov::Syncers::TaskChainSyncer"

    def initialize(client: Tarkov::Client.new, logger: Rails.logger, fandom_client: nil)
      @client = client
      @logger = logger
      @fandom_client = fandom_client
    end

    def call
      results = {}

      # Core entities (items, traders, tasks) — must commit before derived steps
      ActiveRecord::Base.transaction do
        run_steps(results, :items, :traders, :tasks, :task_chains)
      end

      # Derived unlocks (barters, crafts) — depend on core entities
      ActiveRecord::Base.transaction do
        run_steps(results, :barters, :crafts)
      end

      # Purge steps — remove stale data after unlocks are settled
      ActiveRecord::Base.transaction do
        run_steps(results, :historical_purge, :trader_purge, :junk_purge)
      end

      # Cleanup — alias hygiene and denormalized name refresh
      ActiveRecord::Base.transaction do
        run_steps(results, :aliases, :refresh_names)
      end

      results
    end

    private

    attr_reader :logger, :fandom_client

    def run_steps(results, *step_keys)
      step_keys.each do |step|
        klass = STEPS.fetch(step)
        log "syncing #{step}..."
        results[step] = build_syncer(klass).call
        log "#{step}: #{results[step]} records"
      end
    end

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
