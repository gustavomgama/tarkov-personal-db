module Tarkov
  class Syncer
    STEPS = {
      items: "Tarkov::Syncers::ItemSyncer",
      traders: "Tarkov::Syncers::TraderSyncer",
      tasks: "Tarkov::Syncers::TaskSyncer",
      barters: "Tarkov::Syncers::TraderItemSyncer",
      hideout: "Tarkov::Syncers::HideoutSyncer"
    }.freeze

    def initialize(client: Tarkov::Client.new, logger: Rails.logger)
      @client = client
      @logger = logger
    end

    def call
      STEPS.each_with_object({}) do |(step, klass), results|
        log "syncing #{step}..."
        results[step] = klass.constantize.new(client: @client).call
        log "#{step}: #{results[step]} records"
      end
    end

    private

    attr_reader :logger

    def log(message)
      logger.info("[tarkov:sync] #{message}")
    end
  end
end
