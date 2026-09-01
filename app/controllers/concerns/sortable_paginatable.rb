module SortablePaginatable
  extend ActiveSupport::Concern

  DEFAULT_PER = 50
  PER_RANGE = (10..200)
  PER_OPTIONS = [ 10, 25, 50, 100, 200 ].freeze

  private

  # Whitelisted ORDER BY from params. +sorts+ maps param values to either an
  # SQL column fragment or a callable receiving "ASC"/"DESC" (for clauses that
  # must pin NULL placement independent of direction).
  def sort_order(sorts, default:)
    column = sorts.fetch(params[:sort]) { sorts.fetch(default) }
    direction = params[:dir] == "desc" ? "DESC" : "ASC"
    clause = column.respond_to?(:call) ? column.call(direction) : "#{column} #{direction}"
    Arel.sql(clause)
  end

  def requested_per
    value = params.fetch(:per) { DEFAULT_PER }.to_i
    value.clamp(PER_RANGE.min, PER_RANGE.max)
  end

  # Clamps the requested page into the valid range for the filtered scope.
  # +count_scope+ is an optional simpler relation to count when +scope+
  # carries select/group decorations that break COUNT (e.g. grouped joins).
  def paginate(scope, per:, count_scope: nil)
    total = (count_scope || scope).count(:all)
    pages = [ (total.to_f / per).ceil, 1 ].max
    current_page = params.fetch(:page) { 1 }.to_i.clamp(1, pages)
    @total = total
    @pages = pages
    @page = current_page
    scope.offset((current_page - 1) * per).limit(per)
  end
end
