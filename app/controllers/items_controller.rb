class ItemsController < ApplicationController
  SORTS = {
    "name" => "LOWER(name)",
    "price" => "price IS NULL, price",
    "updated" => "updated_at"
  }.freeze

  CATEGORIES = {
    "buyable" => "price IS NOT NULL",
    "ammo" => "categories LIKE '%\"ammo\"%' OR categories LIKE '%\"ammoBox\"%'",
    "gun" => "categories LIKE '%\"gun\"%'",
    "helmet" => "categories LIKE '%\"helmet\"%'",
    "armor" => "categories LIKE '%\"armor\"%' OR categories LIKE '%\"armorPlate\"%'",
    "rig" => "categories LIKE '%\"rig\"%'",
    "backpack" => "categories LIKE '%\"backpack\"%'",
    "headset" => "categories LIKE '%\"headphones\"%'"
  }.freeze

  def index
    @items = Item.order(order_clause)
    @items = Item.token_search(:name, params[:q]).order(order_clause) if params[:q].present?
    currencies = Array(params[:currency]).intersection(%w[RUB USD EUR])
    @items = @items.where(currency: currencies) if currencies.any?
    category_filters.each do |condition|
      @items = @items.where(condition)
    end
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
    @routes = view.routes
    @compatible_guns = view.compatible_guns
    @compatible_ammo = view.compatible_ammo
  end

  private

  def category_filters
    keys = CATEGORIES.keys.intersection(Array(params[:categories]))
    keys.map { |key| CATEGORIES.fetch(key) }
  end

  def order_clause
    column = SORTS.fetch(params[:sort], "name")
    direction = params[:dir] == "desc" ? "DESC" : "ASC"
    Arel.sql("#{column} #{direction}")
  end
end
