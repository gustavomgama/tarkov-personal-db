class ItemsController < ApplicationController
  INDEX_LIMIT = 200

  def index
    @items = Item.order(:name)
    @items = @items.where("LOWER(name) LIKE ?", "%#{params[:q].downcase}%") if params[:q].present?
    @items = @items.where(currency: params[:currency]) if params[:currency].present?
    @items = @items.where(barter: true) if params[:barter] == "1"
    @items = @items.where(craft: true) if params[:craft] == "1"
    @items = @items.where(require_unlock: true) if params[:unlocked] == "1"
    @total = @items.count
    @items = @items.limit(INDEX_LIMIT)
  end

  def show
    @item = Item.find(params[:id])
    @unlock_entries = Tarkov::UnlockPathResolver.new(@item).resolve
    @chain = Tarkov::UnlockPathResolver.merged_chain(@unlock_entries)
    @conditions = build_conditions
    @required_level = @unlock_entries.map(&:required_player_level).compact.max
    @compatible_guns = compatible_guns(@item)
    @compatible_ammo = compatible_ammo(@item)
  end

  private

  def build_conditions
    @unlock_entries.filter_map do |entry|
      trader = entry.unlock.trader_name.presence || entry.unlock.trader&.name
      {
        trader: trader,
        loyalty: entry.unlock.loyalty_level,
        loyalty_cost: loyalty_cost(entry.unlock.trader_id, entry.unlock.loyalty_level),
        types: entry.unlock.unlock_types,
        task: entry.task
      }
    end.compact.uniq { |c| [ c[:trader], c[:loyalty], c[:task]&.id ] }
       .reject { |c| c[:trader].nil? && c[:task].nil? }
  end

  def compatible_guns(item)
    return Item.none unless item.ammo?

    guns = Item.where(gun: true).where("allowed_ammo LIKE ?", "%\"#{item.tid}\"%")
    return guns.order(:name) if guns.any?

    Item.where(gun: true, caliber: item.caliber).order(:name)
  end

  def compatible_ammo(item)
    return Item.none unless item.gun? || item.allowed_ammo.any?

    Item.where(tid: item.allowed_ammo).order(:name)
  end

  def loyalty_cost(trader_id, level)
    return nil if trader_id.nil? || level.nil?

    TraderLoyaltyLevel.find_by(trader_id: trader_id, level: level)
  end
end
