require "test_helper"

module Tarkov
  module Syncers
    class TaskChainSyncerTest < ActiveSupport::TestCase
      setup do
        TaskSyncer.new(client: FakeTarkovClient.new(tasks: tasks_payload)).call
        @supplier = Task.find_by!(tid: "task-1")
        @other = Task.create!(tid: "task-prev", name: "Wet Job - Part 1",
                              wiki_link: "https://escapefromtarkov.fandom.com/wiki/Wet_Job_-_Part_1")
        @supplier.update!(wiki_link: "https://escapefromtarkov.fandom.com/wiki/Supplier")

        wikitext = {
          "Supplier" => "{{Infobox quest|previous=[[Wet Job - Part 1]]|given by=[[Prapor]]}}\nbody",
          "Wet Job - Part 1" => "{{Infobox quest}}\nbody"
        }
        @fandom = FakeFandomClient.new(wikitext: wikitext)
      end

      test "links tasks to their wiki predecessor" do
        count = TaskChainSyncer.new(client: FakeTarkovClient.new, fandom_client: @fandom).call

        assert_equal 1, count
        assert_equal @other.id, @supplier.reload.previous_task_id
        assert_equal "Wet Job - Part 1", @supplier.previous_task_name
        assert_nil @other.reload.previous_task_id
      end

      test "is idempotent on re-run" do
        TaskChainSyncer.new(client: FakeTarkovClient.new, fandom_client: @fandom).call

        assert_equal 0, TaskChainSyncer.new(client: FakeTarkovClient.new, fandom_client: @fandom).call
      end

      test "unresolvable predecessor titles still record the name" do
        wikitext = { "Supplier" => "{{Infobox quest|previous=[[Not Synced Quest]]}}" }
        fandom = FakeFandomClient.new(wikitext: wikitext)

        TaskChainSyncer.new(client: FakeTarkovClient.new, fandom_client: fandom).call

        assert_nil @supplier.reload.previous_task_id
        assert_equal "Not Synced Quest", @supplier.previous_task_name
      end

      test "skips tasks whose wiki link has no page slug" do
        @other.update!(wiki_link: "https://escapefromtarkov.fandom.com/")

        assert_equal 1, TaskChainSyncer.new(client: FakeTarkovClient.new, fandom_client: @fandom).call
        assert_nil @other.reload.previous_task_id
      end

      test "survives invalid updates" do
        original = Task.instance_method(:update!)
        Task.define_method(:update!) { |*| raise ActiveRecord::RecordInvalid.new(self) }

        assert_equal 0, TaskChainSyncer.new(client: FakeTarkovClient.new, fandom_client: @fandom).call
      ensure
        Task.define_method(:update!, original)
      end
    end
  end
end
