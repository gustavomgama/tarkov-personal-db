module Tarkov
  module Syncers
    # Removes items with no acquisition path: nothing buyable, no barter row,
    # no craft row and not gated behind any task. Runs after all unlock
    # writers so freshly synced routes are respected. Usable-goods categories
    # (medical, grenades, provisions, containers) are always kept.
    class ItemPurge < Base
      PROTECTED = [ "medical", "grenades", "provisions", "containers" ].freeze

      def call
        scope = Item.where(price: nil)
                    .where(barter: false, craft: false, require_unlock: false)
                    .where.not(id: ItemUnlock.select(:item_id))
                    .where.not(id: protected_item_ids)
        removed = scope.count
        scope.find_each(&:destroy!)
        removed
      end

      private

      # NULL-safe: items without categories must stay purgeable.
      def protected_item_ids
        conditions = PROTECTED.map { |category| Item.sanitize_sql_array([ "categories LIKE ?", "%\"#{category}\"%" ]) }
                              .join(" OR ")
        Item.where(conditions).select(:id)
      end
    end
  end
end
