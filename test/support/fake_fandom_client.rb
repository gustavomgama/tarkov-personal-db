class FakeFandomClient
  attr_reader :page_queries, :category_queries, :wikitext_queries

  def initialize(pages: {}, category_members: {}, wikitext: {}, search_results: {})
    @pages = pages
    @category_members = category_members
    @wikitext = wikitext
    @search_results = search_results
    @page_queries = []
    @category_queries = []
    @wikitext_queries = []
  end

  def pages(titles)
    @page_queries.concat(titles)
    titles.to_h { |title| [ title, @pages.fetch(title, nil) ] }
  end

  def raw_wikitext(titles)
    @wikitext_queries.concat(titles)
    titles.to_h { |title| [ title, @wikitext.fetch(title, nil) ] }
  end

  def search_titles(query, limit: 5)
    @search_results.fetch(query, [])
  end

  def category_members(category)
    @category_queries << category
    @category_members.fetch(category, [])
  end
end
