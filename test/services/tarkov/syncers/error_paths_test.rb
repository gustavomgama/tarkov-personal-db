require "test_helper"

module Tarkov
  module Syncers
    class ErrorPathsTest < ActiveSupport::TestCase
      setup do
        @item = Item.create!(tid: "i-err", name: "Error Bait")
      end

      test "task syncer skips payload tasks without an id" do
        client = FakeTarkovClient.new(tasks: { "tasks" => { "broken" => { "name" => "No Id" } } })

        assert_equal 0, TaskSyncer.new(client: client).call
      end

      test "offer unlocks tolerate invalid rows" do
        task = Task.create!(tid: "t-offer", name: "Offer Task")
        ghost = Item.create!(tid: "i-offer", name: "Offer Item")

        poison_new(ItemUnlock) do
          silence { TaskSyncer.new(client: fake_offer_client(task, ghost)).call }
        end

        assert_empty task.reload.item_unlocks
      end

      test "task requirements tolerate invalid rows" do
        trader = Trader.create!(tid: "t-req", name: "Req")
        task = Task.create!(tid: "t-base", name: "Base", trader: trader)
        required = Task.create!(tid: "t-prereq", name: "Prereq", trader: trader)

        poison_new(TaskRequirement) do
          silence { TaskSyncer.new(client: FakeTarkovClient.new(tasks: { "tasks" => {
            task.tid => { "id" => task.tid, "name" => task.name,
                          "taskRequirements" => [ { "task" => required.tid } ] }
          } })).call }
        end

        assert_empty task.reload.task_requirements
      end

      test "loyalty levels tolerate invalid rows and bad dates" do
        Trader.create!(tid: "t-loyal", name: "Loyal")

        poison_new(TraderLoyaltyLevel) do
          silence { TraderSyncer.new(client: FakeTarkovClient.new(traders: {
            "t-loyal" => { "id" => "t-loyal", "name" => "Loyal", "resetTime" => "9999-99-99",
                           "levels" => [ { "level" => 1 } ] }
          })).call }
        end

        trader = Trader.find_by!(tid: "t-loyal")
        assert_empty trader.trader_loyalty_levels
        assert_nil trader.reset_time
      end

      test "cash offers tolerate invalid rows" do
        Item.create!(tid: "i-cash", name: "Cash Item")

        poison_new(ItemUnlock) do
          silence { BarterSyncer.new(client: FakeTarkovClient.new(items: {
            "items" => { "i-cash" => { "id" => "i-cash", "buyFromTrader" => [
              { "trader" => "t-loyal", "price" => 5, "priceRUB" => 5, "currency" => "RUB",
                "minTraderLevel" => 1 }
            ] } }
          }, barters: [])).call }
        end

        assert_empty ItemUnlock.all
      end

      private

      def fake_offer_client(task, ghost_item)
        FakeTarkovClient.new(tasks: { "tasks" => {
          task.tid => { "id" => task.tid, "name" => task.name,
                        "finishRewards" => { "offerUnlock" => [
                          { "level" => 2, "item" => { "item" => ghost_item.tid }, "trader" => "ghost" }
                        ] } }
        } })
      end

      def poison_new(klass)
        original_new = klass.method(:new)
        klass.define_singleton_method(:new) do |*args, **kwargs|
          row = original_new.call(*args, **kwargs)
          row.define_singleton_method(:save!) do |*|
            raise ActiveRecord::RecordInvalid.new(self)
          end
          row
        end
        yield
      ensure
        klass.define_singleton_method(:new, original_new)
      end

      def silence(&block)
        old = Rails.logger.level
        Rails.logger.level = Logger::ERROR
        block.call
      ensure
        Rails.logger.level = old
      end
    end
  end
end
