module Tarkov
  module Syncers
    # Final pass: every alias must end at a live Item. Runs after junk_purge
    # because purging can remove items that earlier steps aliased to.
    class AliasHygiene < Base
      def call
        fixed = 0
        ItemAlias.find_each do |alias_row|
          target = live_target(alias_row.canonical_tid) || live_target(alias_row.tid)
          if target
            unless alias_row.canonical_tid == target.tid
              fixed += 1
              alias_row.update_columns(canonical_tid: target.tid)
            end
          else
            alias_row.destroy!
          end
        end
        fixed
      end

      private

      # Follows alias chains until a tid that is a real item (or dead end).
      def live_target(start)
        seen = [ start ]
        cur = start
        while (nxt = ItemAlias.where(tid: cur).pick(:canonical_tid))
          return nil if seen.include?(nxt)

          seen << nxt
          cur = nxt
        end
        Item.find_by(tid: cur)
      end
    end
  end
end
