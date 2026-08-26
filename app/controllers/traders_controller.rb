class TradersController < ApplicationController
  def index
    @traders = Trader.order(:name)
    @gated_counts = ItemUnlock.where.not(task_id: nil).group(:trader_id).count
    fresh_when(etag: [ Trader.maximum(:updated_at), ItemUnlock.maximum(:updated_at) ])
  end

  def show
    @trader = Trader.find(params[:id])
    @loyalty_levels = @trader.trader_loyalty_levels.order(:level)
    @tasks = @trader.tasks.order(:min_player_level, :name)
    @gated_items = Item.gated_for(@trader)
    @sold_items = Item.sold_by(@trader)
    fresh_when(etag: [ @trader, ItemUnlock.where(trader_id: @trader.id).maximum(:updated_at) ])
  end
end
