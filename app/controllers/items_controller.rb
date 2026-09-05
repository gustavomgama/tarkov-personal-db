class ItemsController < ApplicationController
  def index
    @items = Item.all.order(full_name: :asc).limit(20)
    @item_count = Item.count
  end

  def show
    @item = Item.find(params[:id])
  end
end
