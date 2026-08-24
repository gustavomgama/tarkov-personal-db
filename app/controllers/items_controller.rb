class ItemsController < ApplicationController
  INDEX_LIMIT = 200

  def index
    @items = Item.where(quest_item: false).order(:name)
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
    @purchase_routes = purchase_routes
    @needed_for_tasks = needed_for_tasks(@item)
  end

  private

  def purchase_routes
    @item.item_unlocks.of_type("money").includes(:trader, :task).group_by do |row|
      row.trader_name.presence || row.trader&.name || "Unknown trader"
    end
  end

  def needed_for_tasks(item)
    Task.joins(:task_objectives).where(task_objectives: { item: item }).distinct.order(:name)
  end
end
