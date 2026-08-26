class ItemsController < ApplicationController
  include SortablePaginatable

  SORTS = {
    "name" => "LOWER(name)",
    "updated" => "updated_at"
  }.freeze

  def index
    scope = Item.all
    scope = Item.token_search(:name, params[:q]) if params[:q].present?
    # Within a group any match counts (OR); different groups combine (AND).
    if (category_keys = Item::CATEGORIES.keys.intersection(Array(params[:categories]))).any?
      clauses = category_keys.map { |key| [ "categories LIKE ?", "%\"#{key}\"%" ] }
      sql, *binds = clauses.map { |c| "(#{c[0]})" }.join(" OR "), *clauses.flat_map { |c| c[1] }
      scope = scope.where(sql, *binds)
    end
    # Acquisition filters form one OR group: RUB or USD or barterable or
    # craftable or task-gated - an item needs only one of the checked routes.
    currencies = Array(params[:currency]).intersection(%w[RUB USD EUR])
    acquisition = []
    acquisition << Item.arel_table[:currency].in(currencies) unless currencies.empty?
    acquisition << Item.arel_table[:barter].eq(true) if params[:barter] == "1"
    acquisition << Item.arel_table[:ref_gp].eq(true) if params[:gp] == "1"
    acquisition << Item.arel_table[:craft].eq(true) if params[:craft] == "1"
    acquisition << Item.arel_table[:require_unlock].eq(true) if params[:unlocked] == "1"
    scope = scope.where(acquisition.inject(:or)) unless acquisition.empty?
    if params[:trader_id].present?
      trader = Trader.find_by(id: params[:trader_id])
      scope = scope.joins(:item_unlocks).where(item_unlocks: { trader_id: trader&.id }).distinct if trader
    end

    fresh_when(etag: [ Item.maximum(:updated_at), Item.count, request.query_parameters ])
    @per = requested_per
    @items = paginate(scope.order(sort_order(SORTS, default: "name")), per: @per)
  end

  def show
    @item = Item.find_by(slug: params[:slug])
    @item ||= Item.find_by(id: params[:slug]) if params[:slug] =~ /\A\d+\z/
    raise ActiveRecord::RecordNotFound unless @item

    view = Tarkov::ItemAcquisitionView.new(@item)
    @routes = view.routes
    @compatibilities = view.compatibilities
    fresh_when(etag: [ @item, ItemUnlock.where(item_id: @item.id).maximum(:updated_at) ])
  end
end
