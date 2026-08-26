module Tarkov
  # Content removed from the live game (fandom "Category:Historical content").
  # Tasks and items whose names appear here are purged and blocked from
  # re-syncing, so retired event quests and their props never clutter routes.
  module HistoricalContent
    LIST_PATH = Rails.root.join("config/historical_content.yml")

    def self.names
      @names ||= YAML.safe_load_file(LIST_PATH, permitted_classes: [], aliases: false)
                     .fetch("names", []).to_set { |name| normalize(name) }
    end

    def self.historical?(name)
      name.present? && names.include?(normalize(name))
    end

    def self.normalize(name)
      name.to_s.tr("\u2019\u2018", "''").gsub(/\s+/, " ").strip.downcase
    end
  end
end
