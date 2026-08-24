class TradersController < ApplicationController
  def index
    @traders = Trader.order(:name)
  end

  def show
    @trader = Trader.find(params[:id])
    @loyalty_levels = @trader.trader_loyalty_levels.order(:level)
    @gated_items = Item.joins(:item_unlocks).where(item_unlocks: { trader_id: @trader.id })
                       .where.not(item_unlocks: { task_id: nil }).distinct.order(:name)
    @sold_items = Item.joins(:item_unlocks).where(item_unlocks: { trader_id: @trader.id })
                      .where(item_unlocks: { task_id: nil }).distinct.order(price: :desc).limit(50)
  end
end
