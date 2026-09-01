require "test_helper"

# == Schema Information
#
# Table name: tasks
#
#  id                   :bigint           not null, primary key
#  bsg_id               :string           default(""), not null
#  full_name            :string           not null
#  name                 :string           default(""), not null
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
#  index_tasks_on_bsg_id                (bsg_id) UNIQUE WHERE ((bsg_id)::text <> ''::text)
#  index_tasks_on_full_name             (full_name)
#  index_tasks_on_given_by              (given_by)
#  index_tasks_on_kappa_required        (kappa_required)
#  index_tasks_on_lightkeeper_required  (lightkeeper_required)
#  index_tasks_on_name                  (name) UNIQUE WHERE ((name)::text <> ''::text)
#
class TaskTest < ActiveSupport::TestCase
  test "persists literal JSON document fields" do
    task = tasks(:a_big_loss)
    assert_equal "5ae4493d86f7744b8e15aa8f", task.bsg_id
    assert_equal "a-big-loss", task.name
    assert_equal "A Big Loss", task.full_name
    assert_equal "Ragman", task.given_by
    assert task.kappa_required
    assert_not task.lightkeeper_required
  end

  test "stores nested jsonb columns as arrays of hashes" do
    task = tasks(:a_big_loss)
    assert_equal [], task.leads_to
    assert_equal [ { "player_level" => 0, "trader_level" => [], "previous_tasks" => [] } ], task.requirements
    reward = task.finish_rewards.first
    assert_equal "Roubles", reward["loose_items"].first["item_name"]
    assert_equal "80000", reward["loose_items"].first["count"]
  end

  test "stores leads_to and previous_tasks references" do
    task = tasks(:anesthesia)
    assert_equal "rigged-game", task.leads_to.first["task_name"]
    assert_equal "shaking-up-the-teller", task.requirements.first["previous_tasks"].first["task_name"]
    assert_equal 21, task.requirements.first["player_level"]
  end

  test "requires full_name and given_by" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Task.create!(full_name: "", given_by: "")
    end
  end

  test "rejects non-array jsonb columns" do
    task = Task.new(full_name: "X", given_by: "Y", leads_to: { "oops" => true })
    assert_not task.valid?
    assert_includes task.errors[:leads_to], "must be an array"
  end

  test "slug returns name when present" do
    assert_equal "a-big-loss", tasks(:a_big_loss).slug
    task = Task.new(full_name: "No Slug", given_by: "Ref", name: "")
    assert_nil task.slug
  end

  test "scopes filter by flags and trader" do
    assert_includes Task.kappa, tasks(:a_big_loss)
    assert_includes Task.kappa, tasks(:anesthesia)
    assert_includes Task.by_given_by("Ragman"), tasks(:a_big_loss)
    assert_not_includes Task.by_given_by("Ragman"), tasks(:anesthesia)
  end

  test "imports the Collector document from tasks_index.json" do
    doc = JSON.parse(File.read("offlinedata/tarkovunlockables/tasks_index.json"))
      .find { |t| t["full_name"] == "Collector" }
    assert doc

    task = Task.create!(
      bsg_id: doc["id"],
      full_name: doc["full_name"],
      name: doc["name"],
      wiki_link: doc["wiki_link"],
      given_by: doc["given_by"],
      kappa_required: doc["kappa_required"],
      lightkeeper_required: doc["lightkeeper_required"],
      leads_to: doc["leads_to"],
      requirements: doc["requirements"],
      start_rewards: doc["start_rewards"],
      finish_rewards: doc["finish_rewards"]
    )
    task.reload

    assert_equal "5c51aac186f77432ea65c552", task.bsg_id
    assert_equal "Fence", task.given_by
    assert task.kappa_required
    assert_not task.lightkeeper_required
    assert_equal [], task.leads_to
    assert_equal [ { "loose_items" => [], "offer_unlocks" => [], "barter_unlocks" => [], "craft_unlocks" => [] } ], task.start_rewards

    req = task.requirements.first
    assert_equal 0, req["player_level"]
    assert_equal 8, req["trader_level"].length
    assert_equal "Therapist", req["trader_level"].first["trader_name"]
    assert_equal "Fence", req["trader_level"].last["trader_name"]
    assert_equal 3, req["trader_level"].last["trader_level"]
    assert_equal 4, req["previous_tasks"].length
    assert_equal "chemical-part-3", req["previous_tasks"].first["task_name"]

    reward = task.finish_rewards.first
    assert_equal 2, reward["loose_items"].length
    assert_equal "Secure container Kappa", reward["loose_items"].first["item_name"]
    assert_equal [], reward["offer_unlocks"]
    assert_equal [], reward["craft_unlocks"]
  end
end
