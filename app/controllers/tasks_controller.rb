class TasksController < ApplicationController
  SORTS = {
    "name" => "LOWER(tasks.name)",
    "level" => "min_player_level",
    "gates" => "unlocks_count"
  }.freeze

  def index
    @total = Task.count
    direction = params[:dir] == "desc" ? "DESC" : "ASC"
    order = Arel.sql("#{SORTS.fetch(params[:sort], SORTS['name'])} #{direction}")
    scope = Task.left_joins(:item_unlocks)
                .select("tasks.*, COUNT(item_unlocks.id) AS unlocks_count")
                .group("tasks.id").order(order)
    scope = scope.where(trader_id: params[:trader_id]) if params[:trader_id].present?
    scope = scope.where("LOWER(tasks.name) LIKE ?", "%#{params[:q].downcase}%") if params[:q].present?
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    @tasks = scope.offset((@page - 1) * 50).limit(50)
  end

  def show
    @task = Task.find(params[:id])
    @unlocked_items = Item.joins(:item_unlocks).where(item_unlocks: { task_id: @task.id })
                          .distinct.order(:name).includes(:item_unlocks)
    @previous_tasks = @task.required_tasks.presence ||
                      Task.where(id: @task.previous_task_id)
    @next_tasks = @task.unlocking_tasks.presence ||
                  Task.where(id: @task.next_task_id)
  end
end
