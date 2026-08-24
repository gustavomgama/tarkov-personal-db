require "test_helper"

module Tarkov
  class FactCheckerTest < ActiveSupport::TestCase
    setup do
      @item = Item.create!(tid: "i-1", name: "Colt M4A1",
                           wiki_link: "https://escapefromtarkov.fandom.com/wiki/Colt_M4A1")
      @task = Task.create!(tid: "t-1", name: "The Cleaner",
                           wiki_link: "https://escapefromtarkov.fandom.com/wiki/The_Cleaner")
      ItemUnlock.create!(item: @item, item_name: @item.name, task: @task,
                         trader_name: "Peacekeeper", loyalty_level: 4,
                         unlock_types: [ "money" ], source: "dev")

      wikitext = {
        "Colt M4A1" => "{{Infobox weapon|trader=[[Peacekeeper]] LL4, after completing his task [[The Cleaner]]}}\nbody",
        "The Cleaner" => "{{Infobox quest|previous=[[Wet Job - Part 6]]|given by=[[Peacekeeper]]}}\nbody"
      }
      pages = { "Colt M4A1" => "Colt M4A1", "The Cleaner" => "The Cleaner" }
      @fandom = FakeFandomClient.new(pages: pages, wikitext: wikitext)
    end

    test "clean data produces no findings" do
      FactChecker.new(fandom_client: @fandom).call

      assert_empty @fandom.page_queries.grep(/missing/)
    end

    test "reports name drift against canonical wiki titles" do
      @item.update!(name: "Wrong Name")
      checker = FactChecker.new(fandom_client: @fandom)

      checker.call

      assert(checker.instance_variable_get(:@findings)
                    .any? { |f| f[1] == "name-drift" && f[2] == "i-1" })
    end

    test "reports routes the wiki infobox does not support" do
      @task.update!(name: "Some Other Task")
      checker = FactChecker.new(fandom_client: @fandom)

      checker.call

      assert(checker.instance_variable_get(:@findings)
                    .any? { |f| f[1] == "unverified-by-wiki" })
    end

    test "reports chain gaps where wiki knows a predecessor and dev does not" do
      checker = FactChecker.new(fandom_client: @fandom)

      checker.call

      gap = checker.instance_variable_get(:@findings)
                   .find { |f| f[1] == "wiki-knows-predecessor" }
      assert_not_nil gap
      assert_match(/Wet Job - Part 6/, gap[3])
    end

    test "writes a markdown report" do
      silence_stdout { FactChecker.new(fandom_client: @fandom).call }

      assert_path_exists factcheck_report
    ensure
      factcheck_report.delete if factcheck_report.exist?
    end

    test "reports items whose wiki page is missing entirely" do
      @fandom = FakeFandomClient.new(pages: {}, wikitext: {})
      checker = FactChecker.new(fandom_client: @fandom)

      checker.call

      assert(checker.instance_variable_get(:@findings)
                    .any? { |f| f[1] == "missing-page" })
      assert(checker.instance_variable_get(:@findings)
                    .any? { |f| f[1] == "no-wiki-trader-line" })
    end

    test "records lookup failures without raising" do
      broken = Object.new
      def broken.pages(*)
        raise Tarkov::Fandom::Client::Error, "wiki down"
      end

      def broken.raw_wikitext(*)
        {}
      end

      checker = FactChecker.new(fandom_client: broken)

      checker.call

      assert(checker.instance_variable_get(:@findings)
                    .any? { |f| f[1] == "lookup-failed" })
    end

    test "empty database renders a no-drift report" do
      ItemUnlock.destroy_all
      Item.destroy_all
      Task.destroy_all
      checker = FactChecker.new(fandom_client: @fandom)

      silence_stdout { checker.call }

      assert_empty checker.instance_variable_get(:@findings)
      assert_path_exists factcheck_report
      assert_match "No drift detected", factcheck_report.read
    ensure
      factcheck_report.delete if factcheck_report.exist?
    end

    private

    def factcheck_report
      Pathname.new(Rails.root.join("log")).glob("factcheck-*.md").first ||
        Rails.root.join("log", "factcheck-none.md")
    end

    def silence_stdout(&block)
      original = $stdout
      $stdout = StringIO.new
      block.call
    ensure
      $stdout = original
    end
  end
end
