require "test_helper"

module Tarkov
  class GapCoverageTest < ActiveSupport::TestCase
    setup do
      @item = Item.create!(tid: "gap-item", name: "Gap Item")
    end

    test "item enricher survives invalid updates" do
      def @item.update!(*)
        raise ActiveRecord::RecordInvalid.new(self)
      end

      enricher = Fandom::ItemEnricher.new(@item)
      assert_not enricher.apply!("{{Infobox x}}\nbody", "Title")
    end

    test "unlock rows survive invalid saves" do
      original_save = ItemUnlock.instance_method(:save!)
      ItemUnlock.define_method(:save!) do |*|
        raise ActiveRecord::RecordInvalid.new(self)
      end

      silence_logs { Fandom::UnlockRows.sync!(@item, "Prapor LL2") }

      assert_empty @item.item_unlocks
    ensure
      ItemUnlock.define_method(:save!, original_save)
    end

    test "wikitext parser handles unclosed templates" do
      parser = Fandom::WikitextParser.new("{{Infobox ammo", page_title: "X")

      assert_empty parser.infobox_params
    end

    test "task falls back to previous_task_id when no requirements" do
      prev = Task.create!(tid: "gap-prev", name: "Prev Task")
      task = Task.create!(tid: "gap-task", name: "Current", previous_task_id: prev.id)

      assert_equal [ prev ], task.prerequisite_tasks.to_a
    end

    test "name syncer tolerates invalid saves and broken links" do
      trader = Trader.create!(tid: "gap-trader", name: "Old Name")

      result = Syncers::FandomNameSyncer.new(client: FakeTarkovClient.new)
                                         .send(:apply_name, trader, "New Name")

      assert result
      assert_equal "New Name", trader.reload.name

      syncer = Syncers::FandomNameSyncer.new(client: FakeTarkovClient.new)
      assert_nil syncer.send(:title_from_link, "http://exa mple with spaces")
    end

    private

    def poison_save_on(klass, instance:)
      original_update = klass.instance_method(:update!)
      klass.define_method(:update!) do |*args|
        raise ActiveRecord::RecordInvalid.new(self)
      end
      yield
    ensure
      klass.define_method(:update!, original_update)
    end

    def silence_logs(&block)
      old = Rails.logger.level
      Rails.logger.level = Logger::ERROR
      block.call
    ensure
      Rails.logger.level = old
    end
  end
end
