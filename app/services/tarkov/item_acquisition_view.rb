module Tarkov
  # Presents one item's acquisition routes as ordered player instructions, plus
  # gun/ammo compatibility. Extracted from ItemsController so the web layer only
  # assigns what the templates render.
  class ItemAcquisitionView
    def initialize(item)
      @item = item
      @unlock_entries = UnlockPathResolver.new(item).resolve
    end

    # The product centerpiece: every way to get the item, expressed as ordered
    # instructions. Routes with fewer tasks come first ("easiest"), ties broken
    # by the lowest total player level gate.
    def routes
      @unlock_entries.group_by { |entry| entry.task&.id }.map do |_task_id, entries|
        lead = entries.first
        # Deeper prerequisites come first: that is the order a player completes them.
        steps = lead.task ? lead.prerequisites.sort_by { |node| -node[:depth] }
                                             .map { |node| node[:task] } + [ lead.task ] : []
        actions = entries.flat_map { |e| e.unlock.unlock_types }.uniq
        traders = entries.filter_map do |e|
          name = e.unlock.trader_name.presence || e.unlock.trader&.name
          next if name.blank?

          { name: name, loyalty: e.unlock.loyalty_level }
        end.uniq { |t| [ t[:name], t[:loyalty] ] }.sort_by { |t| t[:loyalty].to_i }
        {
          tasks: steps,
          actions: actions,
          traders: traders,
          required_level: entries.map(&:required_player_level).compact.max
        }
      end.sort_by { |route| [ route[:tasks].size, route[:required_level].to_i ] }
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
  end
end
