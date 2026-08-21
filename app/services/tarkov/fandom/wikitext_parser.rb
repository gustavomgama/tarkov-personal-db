module Tarkov
  module Fandom
    class WikitextParser
      def initialize(wikitext, page_title:)
        @wikitext = wikitext.to_s
        @page_title = page_title.to_s
      end

      def infobox_params
        @infobox_params ||= parse_infobox_params
      end

      def lead_description
        @lead_description ||= parse_lead_description
      end

      private

      def parse_infobox_params
        block = template_block
        return {} unless block&.start_with?("{{Infobox")

        body = block[2..-3].sub(/\AInfobox[^|]*/, "")
        params = {}
        buffer = String.new
        index = 0

        while index < body.length
          two = body[index, 2]
          if %w[{{ }} [[ ]]].include?(two)
            buffer << two
            index += 2
          elsif body[index] == "|" && nested_depth(buffer).zero?
            flush_param(params, buffer)
            index += 1
          else
            buffer << body[index]
            index += 1
          end
        end
        flush_param(params, buffer)
        params.transform_values { |value| clean(value) }
      end

      def parse_lead_description
        source = @wikitext[/\}\}\s*(.*)\z/m, 1] || @wikitext
        paragraph = source.lines.map(&:strip).reject(&:empty?).first.to_s
        clean(paragraph.gsub(/\{\{PAGENAME\}\}/i, @page_title))
      end

      def template_block
        start = @wikitext.index("{{")
        return unless start

        depth = 0
        index = start
        while index < @wikitext.length - 1
          two = @wikitext[index, 2]
          if two == "{{"
            depth += 1
            index += 2
          elsif two == "}}"
            depth -= 1
            index += 2
            return @wikitext[start...index] if depth.zero?
          else
            index += 1
          end
        end
        nil
      end

      def nested_depth(text)
        text.scan(/\{\{|\[\[/).size - text.scan(/\}\}|\]\]/).size
      end

      def flush_param(params, buffer)
        key, value = buffer.split("=", 2)
        params[key.strip] = value.to_s.strip if key && !key.strip.empty?
        buffer.clear
      end

      def clean(text)
        text.dup
            .gsub(/\[\[([^|\]]*)\|([^\]]*)\]\]/) { Regexp.last_match(2) }
            .gsub(/\[\[([^\]]*)\]\]/) { Regexp.last_match(1).split("|").last }
            .gsub(/\{\{[^{}]*\}\}/, "")
            .gsub(/<[^>]+>/, " ")
            .gsub(/'''''|'''|''/, "")
            .gsub("&nbsp;", " ")
            .gsub(/\s+/, " ")
            .strip
      end
    end
  end
end
