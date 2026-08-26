class TasksController < ApplicationController
  include SortablePaginatable

  SORTS = {
    "name" => "LOWER(tasks.name)",
    "level" => "min_player_level",
    "gates" => "unlocks_count"
  }.freeze

  def index
    filtered = Task.all
    filtered = filtered.where(trader_id: params[:trader_id]) if params[:trader_id].present?
    filtered = filtered.merge(Task.token_search(:name, params[:q])) if params[:q].present?
    filtered = filtered.where(kappa_required: true) if params[:kappa] == "1"

    fresh_when(etag: [ Task.maximum(:updated_at), ItemUnlock.maximum(:updated_at), request.query_parameters ])
    @per = requested_per
    listed = filtered.left_joins(:item_unlocks)
                     .select("tasks.*, COUNT(item_unlocks.id) AS unlocks_count")
                     .group("tasks.id")
                     .order(sort_order(SORTS, default: "name"))
    @tasks = paginate(listed.includes(:trader), per: @per, count_scope: filtered)
  end

  def show
    @task = Task.find(params[:id])
    @unlocked_items = Item.joins(:item_unlocks).where(item_unlocks: { task_id: @task.id })
                          .distinct.order(:name).includes(:item_unlocks)
    @unlocks_for_task = @task.item_unlocks.index_by(&:item_id)
    chain = Tarkov::TaskChainView.new(@task).call
    @requires_chain = chain[:requires]
    @leads_to_chain = chain[:leads_to]
    @previous_tasks = @task.prerequisite_tasks
    @next_tasks = @task.unlocking_tasks.presence ||
                  Task.where(id: @task.next_task_id)
    fresh_when(etag: [ @task, ItemUnlock.where(task_id: @task.id).maximum(:updated_at) ])
  end
end
