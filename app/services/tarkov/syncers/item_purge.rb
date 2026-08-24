module Tarkov
  module Syncers
    # Removes items with no acquisition path: nothing buyable, no barter row,
    # no craft row and not gated behind any task. Runs after all unlock
    # writers so freshly synced routes are respected.
    class ItemPurge < Base
      def call
        scope = Item.where(price: nil)
                    .where(barter: false, craft: false, require_unlock: false)
                    .where.not(id: ItemUnlock.select(:item_id))
        removed = scope.count
        scope.find_each(&:destroy!)
        removed
      end
    end
  end
end
