class ItemsController < ApplicationController
  INDEX_LIMIT = 200

  def index
    @items = Item.order(:name)
    @items = Item.token_search(:name, params[:q]).order(:name) if params[:q].present?
    @items = @items.where(currency: params[:currency]) if params[:currency].present?
    @items = @items.where(barter: true) if params[:barter] == "1"
    @items = @items.where(craft: true) if params[:craft] == "1"
    @items = @items.where(require_unlock: true) if params[:unlocked] == "1"
    @total = @items.count
    @per = [ [ params.fetch(:per, 10).to_i, 10 ].max, 200 ].min
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    @items = @items.offset((@page - 1) * @per).limit(@per)
  end

  def show
    @item = Item.find(params[:id])
    view = Tarkov::ItemAcquisitionView.new(@item)
    @conditions = view.conditions
    @required_level = view.required_level
    @compatible_guns = view.compatible_guns
    @compatible_ammo = view.compatible_ammo
    @tree_roots, @tree_children = view.chain_tree
    @unlock_task_ids = view.unlock_task_ids
  end

  private
end
