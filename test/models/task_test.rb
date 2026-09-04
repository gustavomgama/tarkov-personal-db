require "test_helper"

# == Schema Information
#
# Table name: tasks
#
#  id                   :bigint           not null, primary key
#  bsg_id               :string           not null
#  name                 :string           not null
#  full_name            :string           not null
#  wiki_link            :string           default(""), not null
#  given_by             :string           not null
#  kappa_required       :boolean          default(FALSE), not null
#  lightkeeper_required :boolean          default(FALSE), not null
#  leads_to             :jsonb            not null
#  requirements         :jsonb            not null
#  start_rewards        :jsonb            not null
#  finish_rewards       :jsonb            not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_tasks_on_bsg_id    (bsg_id) UNIQUE
#  index_tasks_on_given_by  (given_by)
#  index_tasks_on_name      (name) UNIQUE
#
class TaskTest < ActiveSupport::TestCase
  test "persists task fields" do
    task = tasks(:a_big_loss)
    assert_equal "5ae4493d86f7744b8e15aa8f", task.bsg_id
    assert_equal "a-big-loss", task.name
    assert_equal "A Big Loss", task.full_name
    assert_equal "ragman", task.given_by
    assert_equal true, task.kappa_required
    assert_equal false, task.lightkeeper_required
  end

  test "stores nested jsonb columns" do
    task = tasks(:a_big_loss)
    assert_equal [], task.leads_to
    assert_equal [ { "player_level" => "0", "trader_level" => [], "previous_tasks" => [] } ], task.requirements
  end

  test "requirements returns jsonb column" do
    task = tasks(:a_big_loss)
    assert_equal [ { "player_level" => "0", "trader_level" => [], "previous_tasks" => [] } ], task.requirements
  end

  test "rewards returns start and finish rewards" do
    task = tasks(:a_big_loss)
    rewards = task.rewards
    assert_equal 2, rewards.length
    assert_equal [], rewards[0]["loose_items"]
    assert_equal "80000", rewards[1]["loose_items"].first["count"]
  end

  test "trader association" do
    task = tasks(:a_big_loss)
    assert_equal "Ragman", task.trader.name
  end

  test "requires bsg_id and name" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Task.create!(bsg_id: "", name: "")
    end
  end
end
