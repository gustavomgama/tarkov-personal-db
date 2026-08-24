class TasksController < ApplicationController
  def index
    @tasks = Task.order(:name)
    @tasks = @tasks.where(trader_id: params[:trader_id]) if params[:trader_id].present?
    @tasks = @tasks.where("LOWER(name) LIKE ?", "%#{params[:q].downcase}%") if params[:q].present?
    @total = @tasks.count
    @tasks = @tasks.limit(200)
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
