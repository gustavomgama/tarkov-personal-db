module Tarkov
  module Syncers
    class HideoutSyncer < Base
      def call
        stations = client.hideout
        upsert_all_stations(stations)
        stations.each_value { |attrs| sync_levels(attrs) }
        stations.size
      end

      private

      def upsert_all_stations(stations)
        stations.each_value do |attrs|
          upsert!(find_station(attrs), { name: attrs["name"] })
        end
      end

      def find_station(attrs)
        HideoutStation.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def sync_levels(attrs)
        station = find_station(attrs)
        Array(attrs["levels"]).each { |level_attrs| sync_level(station, level_attrs) }
      end

      def sync_level(station, attrs)
        level = upsert!(find_level(station, attrs), level_attributes(attrs))
        sync_item_requirements(level, attrs["itemRequirements"])
        sync_requirements(level, attrs)
        level
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] hideout level #{attrs['id']} skipped: #{e.message}")
      end

      def find_level(station, attrs)
        station.hideout_levels.find_or_initialize_by(level: attrs.fetch("level"))
      end

      def level_attributes(attrs)
        {
          construction_time: attrs["constructionTime"],
          description: attrs["description"]
        }
      end

      def sync_item_requirements(level, requirements)
        Array(requirements).each do |requirement|
          item = Item.find_by(tid: requirement["item"])
          unless item
            Rails.logger.warn("[tarkov:sync] hideout level #{level.id} references unknown item #{requirement['item']}")
            next
          end
          record = HideoutItemRequirement.find_or_initialize_by(hideout_level: level, item: item)
          upsert!(record, { count: requirement["count"] })
        end
      end

      def sync_requirements(level, attrs)
        requirement_rows(level, attrs).each do |type, target_name, required_level|
          record = HideoutRequirement.find_or_initialize_by(
            hideout_level: level,
            requirement_type: type,
            target_name: target_name
          )
          upsert!(record, { level: required_level })
        end
      end

      def requirement_rows(level, attrs)
        rows = []
        Array(attrs["stationLevelRequirements"]).each do |requirement|
          target = HideoutStation.find_by(tid: requirement["station"])
          rows << [ "station", target&.name || requirement["station"], requirement["level"] ]
        end
        Array(attrs["traderRequirements"]).each do |requirement|
          target = Trader.find_by(tid: requirement["trader"])
          rows << [ "trader", target&.name || requirement["trader"], requirement["value"] ]
        end
        Array(attrs["skillRequirements"]).each do |requirement|
          rows << [ "skill", requirement["skill"], requirement["level"] ]
        end
        rows
      end
    end
  end
end
