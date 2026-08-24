module Tarkov
  # Presents one item's acquisition routes: unlock entries, merged prerequisite
  # chain, route conditions and gun/ammo compatibility. Extracted from
  # ItemsController so the web layer only assigns what the templates render.
  class ItemAcquisitionView
    def initialize(item)
      @item = item
      @unlock_entries = UnlockPathResolver.new(item).resolve
      @chain = UnlockPathResolver.merged_chain(@unlock_entries)
    end

    def required_level
      @unlock_entries.filter_map(&:required_player_level).compact.max
    end

    def conditions
      @unlock_entries.filter_map do |entry|
        trader = entry.unlock.trader_name.presence || entry.unlock.trader&.name
        {
          trader: trader,
          trader_record: entry.unlock.trader,
          loyalty: entry.unlock.loyalty_level,
          loyalty_cost: loyalty_cost(entry.unlock.trader_id, entry.unlock.loyalty_level),
          types: entry.unlock.unlock_types,
          task: entry.task
        }
      end.compact.uniq { |c| [ c[:trader], c[:loyalty], c[:task]&.id ] }
         .reject { |c| c[:trader].nil? && c[:task].nil? }
    end

    def chain_tree
      ids = @chain.map(&:id).to_set
      children = Hash.new { |h, k| h[k] = [] }
      roots = []
      @chain.each do |task|
        parents = task.prerequisite_tasks.select { |pre| ids.include?(pre.id) }
        parents.empty? ? roots << task : parents.each { |pre| children[pre.id] << task }
      end
      [ roots, children ]
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

    def unlock_task_ids
      @unlock_entries.filter_map { |entry| entry.task&.id }.to_set
    end

    private

    def loyalty_cost(trader_id, level)
      return nil if trader_id.nil? || level.nil?

      TraderLoyaltyLevel.find_by(trader_id: trader_id, level: level)
    end
  end
end
