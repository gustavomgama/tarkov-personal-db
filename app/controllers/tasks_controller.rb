class TasksController < ApplicationController
  def index
    @tasks = Task.all.order(full_name: :asc).limit(20)
    @task_count = Task.count
  end

  def show
    @task = Task.find(params[:id])
  end
end
