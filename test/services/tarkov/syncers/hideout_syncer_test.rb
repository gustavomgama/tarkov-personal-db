require "test_helper"

module Tarkov
  module Syncers
    class HideoutSyncerTest < ActiveSupport::TestCase
      setup do
        ItemSyncer.new(client: FakeTarkovClient.new(items: item_payload)).call
        TraderSyncer.new(client: FakeTarkovClient.new(traders: trader_payload)).call
      end

      test "creates stations, levels, item requirements and requirements" do
        count = HideoutSyncer.new(client: fake_client).call

        assert_equal 2, count
        station = HideoutStation.find_by!(tid: "station-1")
        assert_equal "Generator", station.name

        level = station.hideout_levels.sole
        assert_equal 1, level.level
        assert_equal 60, level.construction_time
        assert_equal "Basic generator", level.description

        item_requirement = level.hideout_item_requirements.sole
        assert_equal "item-1", item_requirement.item.tid
        assert_equal 2, item_requirement.count

        requirements = level.hideout_requirements.index_by(&:requirement_type)
        assert_equal "Water Collector", requirements.fetch("station").target_name
        assert_equal 2, requirements.fetch("station").level
        assert_equal "Prapor", requirements.fetch("trader").target_name
        assert_equal 3, requirements.fetch("trader").level
        assert_equal "HideoutManagement", requirements.fetch("skill").target_name
        assert_equal 5, requirements.fetch("skill").level
      end

      test "resolves station requirement names across the same payload" do
        HideoutSyncer.new(client: fake_client).call

        requirement = HideoutRequirement.find_by(requirement_type: "station")
        assert_equal "Water Collector", requirement.target_name
      end

      private

      def fake_client
        FakeTarkovClient.new(hideout: hideout_payload)
      end
    end
  end
end
