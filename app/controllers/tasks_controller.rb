class TasksController < ApplicationController
  def index
    @total = Task.count
    scope = Task.left_joins(:item_unlocks)
                .select("tasks.*, COUNT(item_unlocks.id) AS unlocks_count")
                .group("tasks.id").order(:name)
    scope = scope.where(trader_id: params[:trader_id]) if params[:trader_id].present?
    scope = scope.where("LOWER(tasks.name) LIKE ?", "%#{params[:q].downcase}%") if params[:q].present?
    @tasks = scope.limit(200)
  end

  def show
    @task = Task.find(params[:id])
    @unlocked_items = Item.joins(:item_unlocks).where(item_unlocks: { task_id: @task.id }).distinct.order(:name)
    @previous_tasks = @task.required_tasks.presence ||
                      Task.where(id: @task.previous_task_id)
    @next_tasks = @task.unlocking_tasks.presence ||
                  Task.where(id: @task.next_task_id)
  end
end
