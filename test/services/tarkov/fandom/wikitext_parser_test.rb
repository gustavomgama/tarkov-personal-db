require "test_helper"

module Tarkov
  module Fandom
    class WikitextParserTest < ActiveSupport::TestCase
      WIKITEXT = <<~WIKI.freeze
        {{Infobox ammo
        |image              =7.62x51 M80 banner.png
        |weight             =0.024 kg
        |grid               =1x1
        |trader             =[[Ref]] LL3<br/>[[Peacekeeper]] LL4, after completing his task [[The Cleaner]]
        |velocity           =820 m/s
        |accuracy           =<font color="red">-13</font>
        |node               =58dd3ad986f77403051cba8f
        }}

        '''{{PAGENAME}}''' (M80) is a [[7.62x51mm NATO|7.62x51mm ammunition]] type in ''[[Escape from Tarkov]]''.
      WIKI

      def parser
        WikitextParser.new(WIKITEXT, page_title: "7.62x51mm M80")
      end

      test "extracts infobox params with nested markup intact" do
        params = parser.infobox_params

        assert_equal "0.024 kg", params["weight"]
        assert_equal "1x1", params["grid"]
        assert_equal "Ref LL3 Peacekeeper LL4, after completing his task The Cleaner", params["trader"]
        assert_equal "58dd3ad986f77403051cba8f", params["node"]
      end

      test "does not split params on pipes inside links" do
        wikitext = "{{Infobox item\n|slot =[[7.62x51mm NATO|7.62x51mm ammunition]]\n}}\nBody."
        params = WikitextParser.new(wikitext, page_title: "X").infobox_params

        assert_equal "7.62x51mm ammunition", params["slot"]
      end

      test "extracts lead description resolving PAGENAME and piped links" do
        assert_equal(
          "7.62x51mm M80 (M80) is a 7.62x51mm ammunition type in Escape from Tarkov.",
          parser.lead_description
        )
      end

      test "handles pages without an infobox" do
        result = WikitextParser.new("Just text.", page_title: "X")

        assert_empty result.infobox_params
        assert_equal "Just text.", result.lead_description
      end
    end
  end
end
