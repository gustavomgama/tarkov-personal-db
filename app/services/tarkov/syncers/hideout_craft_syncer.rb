module Tarkov
  module Syncers
    class HideoutCraftSyncer < Base
      def call
        crafts = client.crafts
        kept_tids = []
        crafts.each do |attrs|
          sync_craft(attrs)
          kept_tids << attrs["id"]
        end
        HideoutCraft.where.not(tid: kept_tids).destroy_all
        crafts.size
      end

      private

      def sync_craft(attrs)
        station = HideoutStation.find_by(tid: attrs["station"])
        return unless station

        craft = upsert!(find_craft(attrs), {
          hideout_station_id: station.id,
          level: attrs["level"],
          duration: attrs["duration"]
        })
        task = Task.find_by(tid: attrs["taskUnlock"])
        mark_crafted_item(attrs, task)
        sync_items(craft, "required", attrs["requiredItems"])
        product = attrs["productItem"]
        rewards = product ? [ { "item" => product["item"], "count" => product["count"] } ] : []
        sync_items(craft, "reward", rewards)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] craft #{attrs['id']} skipped: #{e.message}")
      end

      def mark_crafted_item(attrs, task)
        product = attrs["productItem"]
        item = product && Item.find_by(tid: product["item"])
        return unless item

        item.update!(craft: true)
        return unless task

        row = ItemUnlock.find_or_initialize_by(item: item, task_id: task.id).tap { |row| row.unlock_types = [ "craft" ] }
        row.assign_attributes(item_name: item.name)
        row.save!
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("[tarkov:sync] craft unlock for #{attrs['id']} skipped: #{e.message}")
      end

      def find_craft(attrs)
        HideoutCraft.find_or_initialize_by(tid: attrs.fetch("id"))
      end

      def sync_items(craft, kind, requirements)
        craft.craft_items.where(kind: kind).destroy_all
        Array(requirements).each do |requirement|
          item = Item.find_by(tid: requirement["item"])
          unless item
            Rails.logger.warn("[tarkov:sync] craft #{craft.tid} references unknown #{kind} item #{requirement['item']}")
            next
          end
          CraftItem.create!(hideout_craft: craft, item: item, kind: kind, count: requirement["count"])
        end
      end
    end
  end
end
