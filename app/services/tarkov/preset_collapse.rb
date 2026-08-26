module Tarkov
  # Collapses weapon variant families into one canonical item per weapon.
  #
  # tarkov.dev's bare normalizedName ("colt-m4a1-556x45-assault-rifle") is just
  # the official name anchor - the real, purchasable variants extend it
  # ("-default", "-carbine", trader builds) and share one fandom wiki page.
  # The bare entry is always discarded. The keeper is the family's "-default"
  # preset when one exists (99% of cases), otherwise the shortest extending
  # variant. Every reference (unlocks, barter ingredients, tid lookups) is
  # repointed to it.
  class PresetCollapse
    DEFAULT_SUFFIX = "-default"

    def initialize(item_attrs_list)
      @canonical = {}
      @bases = {}
      @presets = item_attrs_list.select { |a| preset?(a) }
      defaults = @presets.select { |a| default?(a) }

      by_slug = item_attrs_list.group_by { |a| a["normalizedName"].to_s }
      by_slug.each_value do |variants|
        base = variants.find { |a| !preset?(a) }
        next unless base

        @bases[base["normalizedName"].to_s] = base
      end
      @default_for_base = defaults.index_by { |d| d["normalizedName"].to_s.delete_suffix(DEFAULT_SUFFIX) }

      # Keepers first: every -default maps to itself.
      defaults.each { |d| @canonical[d.fetch("id")] = d.fetch("id") }

      # A bare official-name gun with extensions is never kept: it folds onto
      # its family keeper (-default preferred, else shortest variant).
      # Standalone guns without any variant keep their own row.
      @bases.each_value do |base|
        keeper = family_keeper(base) || base
        @canonical[base.fetch("id")] = keeper.fetch("id")
      end

      # Other presets fold onto their family keeper too.
      (@presets - defaults).each do |preset|
        keeper = keeper_for_preset(preset["normalizedName"].to_s)
        @canonical[preset.fetch("id")] = keeper.fetch("id") if keeper
      end

      collapse_wiki_colorways(item_attrs_list)
      fold_sibling_defaults(item_attrs_list)
    end

    # Canonical tid for any upstream tid (identity for kept/unknown ids).
    def resolve(tid)
      @canonical.fetch(tid, tid)
    end

    # True when this upstream id must not become its own Item row.
    def drop?(tid)
      @canonical.fetch(tid, tid) != tid
    end

    # Any keeper preset inherits identity fields (caliber, allowed ammo, slot
    # relations, category-driving types) from its family's bare official name.
    def merge_base_into(preset_attrs)
      base = base_for(preset_attrs["normalizedName"].to_s)
      return preset_attrs unless base

      preset_attrs.merge(
        "types" => base["types"],
        "properties" => base["properties"] || {}
      )
    end

    # Repoints stored references away from folded variants, removes the
    # duplicates, records tid aliases for future upstream payloads and prunes
    # their downloaded images. Idempotent.
    def remap_records!
      dropped_tids = @canonical.keys.select { |tid| drop?(tid) }

      dropped_tids.each do |dropped_tid|
        ItemAlias.find_or_create_by!(tid: dropped_tid) { |alias_row|
          alias_row.canonical_tid = terminal_tid(dropped_tid)
        }.update!(canonical_tid: terminal_tid(dropped_tid))
      end
      # A previous run's alias may point at something folded in this one.
      ItemAlias.where(canonical_tid: dropped_tids).find_each do |alias_row|
        alias_row.update!(canonical_tid: terminal_tid(alias_row.canonical_tid))
      end

      Item.where(tid: dropped_tids).find_each { |duplicate| collapse_duplicate(duplicate) }

      ItemUnlock.where.not(required_items: []).find_each do |row|
        remapped = Array(row.required_items).map do |ingredient|
          resolved = terminal_tid(ingredient["tid"])
          resolved == ingredient["tid"] ? ingredient : ingredient.merge("tid" => resolved)
        end
        row.update_columns(required_items: remapped) if remapped != row.required_items
      end
      dedupe_unlocks!
    end

    private

    def preset?(attrs)
      Array(attrs["types"]).include?("preset")
    end

    def default?(attrs)
      attrs["normalizedName"].to_s.end_with?(DEFAULT_SUFFIX)
    end

    def keeper_for_preset(preset_slug)
      base = base_for(preset_slug)
      return nil unless base

      family_keeper(base) || base
    end

    # The family's canonical variant:
    #   1. the plain -default preset (99% of weapons)
    #   2. the extending preset whose flea price equals the bare anchor's
    #      (upstream prices the true standard under both ids: M4A1 -> carbine,
    #      M16A1 -> m16a1e1, SCAR-L -> lb, DVL-10 -> urbana)
    #   3. otherwise the shortest trader-sold variant, then simply the shortest
    # nil when the family has no presets at all (standalone gun).
    def family_keeper(base)
      slug = base["normalizedName"].to_s
      candidates = @presets.select { |preset| preset["normalizedName"].to_s.start_with?("#{slug}-") }
      return nil if candidates.empty?

      defaults, variants = candidates.partition { |preset| default?(preset) }
      return shortest(defaults) if defaults.any?

      bare_price = base["avg24hPrice"]
      if bare_price.present?
        priced = variants.select { |preset| preset["avg24hPrice"] == bare_price }
        return shortest(priced) if priced.any?
      end

      sold = variants.select { |preset| Array(preset["buyFromTrader"]).any? }
      shortest(sold.presence || variants)
    end

    def shortest(presets)
      presets.min_by { |preset| [ preset["normalizedName"].to_s.length, preset["normalizedName"].to_s ] }
    end

    # Longest bare official-name that prefixes this preset's slug.
    def base_for(preset_slug)
      best = @bases.keys.select { |base| preset_slug.start_with?(base) && base.length < preset_slug.length }
                    .max_by(&:length)
      @bases[best]
    end

    # Colorway variants (plum/FDE magazines, anodized handguards...) share one
    # wiki page. The bare form wins when one exists; otherwise the shortest
    # slug represents the family - either way exactly one entry per page.
    def collapse_wiki_colorways(item_attrs_list)
      item_attrs_list.group_by { |a| a["wikiLink"].to_s.presence }.each do |wiki, members|
        next if wiki.blank? || members.size < 2

        keeper = bare_member(members) ||
                 members.reject { |m| preset?(m) || default?(m) }
                        .min_by { |m| [ m["normalizedName"].to_s.length, m["normalizedName"].to_s ] }
        next unless keeper

        members.each do |member|
          next if member.equal?(keeper)
          # Presets and -default entries are governed by the weapon-family
          # rules above; colorways only fold tinted duplicates into bare parts.
          next if preset?(member) || default?(member)
          next unless related?(keeper, member)

          tid = member.fetch("id")
          # Never undo a genuine collapse; only replace self-mappings.
          @canonical[tid] = keeper.fetch("id") if @canonical[tid].nil? || @canonical[tid] == tid
        end
      end
    end

    # Some weapons ship several `-default` presets (per-colorway defaults).
    # When a wiki family still holds multiple survivors, the shortest slug
    # represents it and its siblings fold in. Unrelated items that merely
    # share a bad wiki link (different slug roots) are left alone.
    def fold_sibling_defaults(item_attrs_list)
      item_attrs_list.group_by { |a| a["wikiLink"].to_s.presence }.each do |wiki, members|
        next if wiki.blank?

        survivors = members.select { |m| @canonical[m.fetch("id")] == m.fetch("id") }
        next if survivors.size < 2

        keeper = survivors.min_by { |m| [ m["normalizedName"].to_s.length, m["normalizedName"].to_s ] }
        related = survivors.select { |m| related?(keeper, m) }
        next if related.size < 2

        keeper = related.min_by { |m| [ m["normalizedName"].to_s.length, m["normalizedName"].to_s ] }
        related.each do |m|
          next if m.equal?(keeper)

          @canonical[m.fetch("id")] = keeper.fetch("id")
        end
      end
    end

    def related?(a, b)
      a["normalizedName"].to_s.split("-").first(2) ==
        b["normalizedName"].to_s.split("-").first(2)
    end

    def bare_member(members)
      members.find do |candidate|
        slug = candidate["normalizedName"].to_s
        slug.present? &&
          members.all? { |m| m["normalizedName"].to_s.start_with?(slug) }
      end
    end

    # Follows fold mappings until a persisted survivor; cycle-safe by design
    # (keepers never map further).
    def terminal_tid(start)
      seen = [ start ]
      cur = start
      while (nxt = @canonical[cur]) && nxt != cur && !seen.include?(nxt)
        seen << nxt
        cur = nxt
      end
      @canonical.fetch(cur, cur)
    end

    def collapse_duplicate(duplicate)
      canonical = Item.find_by(tid: terminal_tid(duplicate.tid))
      ItemUnlock.where(item_id: duplicate.id).update_all(
        item_id: canonical.id, item_name: canonical.name
      )
      duplicate.delete # unlocks were repointed; skip dependent: :destroy
      Dir[Rails.root.join("public/images/items/#{duplicate.tid}*")].each { |file| File.delete(file) }
    end

    # Repointing can leave identical rows (base + preset offering the same
    # thing); keep the oldest of each exact combination.
    def dedupe_unlocks!
      groups = ItemUnlock.order(:id).to_a.group_by do |row|
        [ row.item_id, row.trader_id, row.task_id, row.loyalty_level,
          Array(row.unlock_types).sort, row.source ]
      end
      groups.each_value { |rows| rows.drop(1).each(&:delete) }
    end
  end
end
