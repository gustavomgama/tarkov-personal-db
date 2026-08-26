module Tarkov
  module Syncers
    # Final pass: every alias must end at a live Item. Runs after junk_purge
    # because purging can remove items that earlier steps aliased to.
    class AliasHygiene < Base
      def call
        @alias_map = ItemAlias.where.not(canonical_tid: nil)
                              .where.not(canonical_tid: "")
                              .pluck(:tid, :canonical_tid).to_h
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

      def live_target(start)
        return nil if start.blank?

        seen = [ start ]
        cur = start
        while (nxt = @alias_map[cur])
          return nil if seen.include?(nxt)

          seen << nxt
          cur = nxt
        end
        Item.find_by(tid: cur)
      end
    end
  end
end
