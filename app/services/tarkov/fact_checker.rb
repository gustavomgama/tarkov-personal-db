module Tarkov
  # Read-only verification of the local database against the Fandom wiki.
  # The wiki is the source of truth; this never writes data - it reports drift.
  #
  # Checks:
  # - display names of items/tasks vs canonical wiki titles
  # - task-gated money routes vs the wiki infobox trader line
  # - chain gaps: wiki knows a predecessor the dev payload never carried
  class FactChecker
    def initialize(fandom_client: nil)
      @fandom_client = fandom_client || Fandom::Client.new
      @findings = []
    end

    def call
      check_names("item", Item.where.not(wiki_link: [ nil, "" ]))
      check_names("task", Task.where.not(wiki_link: [ nil, "" ]))
      check_gated_routes
      check_chain_gaps
      report
    end

    private

    attr_reader :fandom_client

    # Wiki canonical titles are truth; local display names come from the
    # json.tarkov.dev localization files and can drift from them.
    def check_names(label, scope)
      records = scope.select { |record| title_from_link(record.wiki_link).present? }
      return if records.empty?

      resolved = fandom_client.pages(records.map { |r| title_from_link(r.wiki_link) })
      records.each do |record|
        canonical = resolved[title_from_link(record.wiki_link)]
        if canonical.nil?
          finding(label, "missing-page", record,
                  "'#{record.name}': wiki page '#{title_from_link(record.wiki_link)}' not found")
        elsif !variant_of?(record.name, canonical)
          finding(label, "name-drift", record, "'#{record.name}' vs wiki '#{canonical}'")
        end
      end
    rescue Fandom::Client::Error => e
      @findings << [ label, "lookup-failed", "-", e.message ]
    end

    # Localized names carry variant/preset suffixes ("(Black)", "Default",
    # "Urbana") over the wiki's canonical title; those are not drift - only a
    # differing core name is.
    def variant_of?(local, wiki)
      one = normalize(local)
      other = normalize(wiki)
      one.start_with?(other) || other.start_with?(one)
    end

    def normalize(name)
      name.to_s.gsub(/\s+/, " ").strip.downcase
    end

    def check_gated_routes
      rows = ItemUnlock.of_type("money").where.not(task_id: nil).includes(:item, :task)
                       .select { |row| title_from_link(row.item.wiki_link).present? }
      texts = fandom_client.raw_wikitext(rows.map { |r| title_from_link(r.item.wiki_link) })

      rows.each do |row|
        trader_line = infobox(texts[title_from_link(row.item.wiki_link)])["trader"].to_s
        if trader_line.blank?
          finding("route", "no-wiki-trader-line", row.item,
                  "'#{row.item.name}' has no wiki infobox trader line to verify '#{row.task.name}'")
        elsif !trader_line.downcase.include?(row.task.name.to_s.downcase)
          finding("route", "unverified-by-wiki", row.item,
                  "'#{row.task.name}' not mentioned for '#{row.item.name}' in wiki infobox ('#{trader_line}')")
        end
      end
    end

    def check_chain_gaps
      required_ids = TaskRequirement.pluck(:required_task_id).to_set
      tasks = Task.where.not(wiki_link: [ nil, "" ])
                  .reject { |task| required_ids.include?(task.id) }
                  .select { |task| title_from_link(task.wiki_link).present? }
      texts = fandom_client.raw_wikitext(tasks.map { |t| title_from_link(t.wiki_link) })

      tasks.each do |task|
        previous = infobox(texts[title_from_link(task.wiki_link)])["previous"]
        next if previous.blank?

        finding("chain", "wiki-knows-predecessor", task,
                "'#{task.name}': wiki lists previous '#{previous}', dev payload has no requirement edge")
      end
    end

    def finding(kind, check, record, detail)
      @findings << [ kind, check, record.respond_to?(:tid) ? record.tid : "-", detail ]
    end

    def infobox(wikitext)
      Fandom::WikitextParser.new(wikitext.to_s, page_title: "").infobox_params
    end

    def title_from_link(link)
      slug = link.to_s[/\/wiki\/(.+)\z/, 1]
      return "" if slug.blank?

      URI.decode_www_form_component(slug).tr("_", " ")
    end

    def report
      path = Rails.root.join("log", "factcheck-#{SyncState.last_synced_version || 'unknown'}.md")
      File.write(path, render_markdown)
      counts = @findings.group_by(&:first).transform_values(&:size)
                        .map { |kind, n| "#{kind}: #{n}" }.join(", ")
      puts "#{@findings.size} findings (#{counts}) -> #{path}"
    end

    def render_markdown
      lines = [ "# Fact-check report", "",
                "- Generated: #{Time.current.iso8601}",
                "- Game version: #{SyncState.last_synced_version || 'unknown'}",
                "- Findings: #{@findings.size}", "" ]
      if @findings.empty?
        lines << "No drift detected."
      else
        lines << "| kind | check | tid | detail |" << "|---|---|---|---|"
        @findings.each { |f| lines << "| #{f[0]} | #{f[1]} | #{f[2]} | #{f[3]} |" }
      end
      lines << ""
      lines.join("\n")
    end
  end
end
