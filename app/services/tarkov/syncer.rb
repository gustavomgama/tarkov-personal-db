module Tarkov
  class Syncer
    STEPS = {
      items: "Tarkov::Syncers::ItemSyncer",
      traders: "Tarkov::Syncers::TraderSyncer",
      tasks: "Tarkov::Syncers::TaskSyncer",
      barters: "Tarkov::Syncers::TraderItemSyncer",
      hideout: "Tarkov::Syncers::HideoutSyncer",
      fandom_names: "Tarkov::Syncers::FandomNameSyncer"
    }.freeze

    def initialize(client: Tarkov::Client.new, logger: Rails.logger, fandom_client: nil)
      @client = client
      @logger = logger
      @fandom_client = fandom_client
    end

    def call
      STEPS.each_with_object({}) do |(step, klass), results|
        log "syncing #{step}..."
        results[step] = build_syncer(klass).call
        log "#{step}: #{results[step]} records"
      end
    end

    private

    attr_reader :logger, :fandom_client

    def build_syncer(klass)
      args = { client: @client }
      args[:fandom_client] = fandom_client if fandom_client && step_uses_fandom?(klass)
      klass.constantize.new(**args)
    end

    def step_uses_fandom?(klass)
      klass == "Tarkov::Syncers::FandomNameSyncer"
    end

    def log(message)
      logger.info("[tarkov:sync] #{message}")
    end
  end
end
