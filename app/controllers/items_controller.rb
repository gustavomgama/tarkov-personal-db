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
    @routes = build_routes(@item)
    @needed_for_tasks = Task.joins(:item_unlocks)
                            .where(item_unlocks: { item_id: @item.id }).distinct.order(:name)
  end

  private

  def build_routes(item)
    Tarkov::UnlockPathResolver.new(item).resolve.map do |entry|
      trader_name = entry.unlock.trader_name.presence || entry.unlock.trader&.name
      {
        trader: trader_name,
        loyalty: entry.unlock.loyalty_level,
        loyalty_cost: loyalty_cost(entry.unlock.trader_id, entry.unlock.loyalty_level),
        types: entry.unlock.unlock_types,
        task: entry.task,
        prerequisites: entry.prerequisites,
        roots: entry.root_quests,
        required_level: entry.required_player_level
      }
    end.reject { |route| route[:trader].nil? && route[:task].nil? }
       .uniq { |route| [ route[:trader], route[:loyalty], route[:task]&.id ] }
  end

  def loyalty_cost(trader_id, level)
    return nil if trader_id.nil? || level.nil?

    TraderLoyaltyLevel.find_by(trader_id: trader_id, level: level)
  end
end
