module Tarkov
  # Presents one item's acquisition routes as ordered player instructions, plus
  # slot compatibility relations. Extracted from ItemsController so the web
  # layer only assigns what the templates render.
  class ItemAcquisitionView
    DEFAULT_SUFFIX = "-default"
    KIND_RANK = { "money" => 0, "barter" => 1, "craft" => 2 }.freeze

    def initialize(item)
      @item = item
      @unlock_entries = UnlockPathResolver.new(item).resolve
    end

    # The product centerpiece: every way to get the item, expressed as ordered
    # player instructions. Routes are grouped per task AND offer type. Ordering
    # is didactic: buyable first, then barters, hideout crafts always last;
    # within a kind, fewer tasks then lower level gates win.
    def routes
      @unlock_entries.group_by { |entry| [ entry.task&.id, primary_type(entry) ] }
                     .map do |_key, entries|
        lead = entries.first
        # Deeper prerequisites come first: that is the order a player completes them.
        steps = lead.task ? lead.prerequisites.sort_by { |node| -node[:depth] }
                                             .map { |node| node[:task] } + [ lead.task ] : []
        offers = entries.map do |entry|
          unlock = entry.unlock
          { type: primary_type(entry), unlock: unlock,
            loyalty: unlock.loyalty_level,
            trader: trader_for(unlock),
            required_items: Array(unlock.required_items),
            station: unlock.station,
            station_level: unlock.station_level,
            gp_currency: unlock.currency == "GP" }
        end.sort_by { |offer| offer[:loyalty].to_i }
        {
          tasks: steps,
          kind: lead_type(entries),
          offers: offers,
          required_level: entries.map(&:required_player_level).compact.max
        }
      end.sort_by { |route| [ KIND_RANK.fetch(route[:kind], 3), route[:tasks].size, route[:required_level].to_i ] }
    end

    def compatible_guns
      return Item.none unless @item.ammo?

      by_allowed = Item.where(gun: true).where("allowed_ammo LIKE ?", "%\"#{@item.tid}\"%")
      by_caliber = @item.caliber ? Item.where(gun: true, caliber: @item.caliber) : Item.none
      (by_allowed.to_a + by_caliber.to_a).uniq.sort_by(&:name)
    end

    def compatible_ammo
      return Item.none unless @item.gun? || @item.allowed_ammo.any?

      Item.where(tid: @item.allowed_ammo).order(:name)
    end

    # Bidirectional slot relations for the Compatibility section:
    # ammo <-> guns, plates <-> armor/rigs, headsets <-> helmets.
    # Gun <-> gun_parts relations are deliberately not shown.
    def compatibilities
      groups = []
      groups << { label: "Used in guns", items: compatible_guns } if @item.ammo?
      groups << { label: "Compatible ammunition", items: compatible_ammo, show_price: true } if @item.gun?
      groups.concat(slot_groups)
      groups
    end

    private

    # Wiki-sourced rows carry only a denormalized trader_name; resolve once.
    def trader_for(unlock)
      return unlock.trader if unlock.trader

      name = unlock.trader_name
      return nil if name.blank?

      @traders_by_name ||= {}
      @traders_by_name[name] = Trader.find_by(name: name) unless @traders_by_name.key?(name)
      @traders_by_name[name]
    end

    def primary_type(entry)
      types = entry.unlock.unlock_types
      %w[money reward barter craft].find { |t| types.include?(t) } || types.first || "money"
    end

    def lead_type(entries)
      primary_type(entries.first)
    end

    def slot_groups
      compat = @item.compat || {}
      groups = []
      case compat["kind"]
      when "plate"
        fits = Item.where("compat LIKE ?", "%\"#{@item.tid}\"%")
                   .where("categories LIKE '%\"armor\"%' OR categories LIKE '%\"armored rig\"%'")
                   .order(:name)
        groups << { label: "Fits into armor / armored rigs", items: fits }
      when "headset"
        blockers = Item.where("categories LIKE '%\"helmet\"%'")
                       .where("compat LIKE '%\"no_headset\":true%'").order(:name)
        if blockers.any?
          groups << { label: "Does NOT fit these helmets", items: blockers }
        else
          groups << { label: "Helmet fit", items: [], note: "Fits in every helmet that accepts headsets." }
        end
      end
      if compat["plates"].present?
        groups << { label: "Accepts ballistic plates",
                    items: Item.where(tid: compat["plates"]).order(:name) }
      end
      groups.select { |group| group[:items].any? || group[:note] }
    end
  end
end
