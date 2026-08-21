class FakeFandomClient
  attr_reader :page_queries, :category_queries

  def initialize(pages: {}, category_members: {})
    @pages = pages
    @category_members = category_members
    @page_queries = []
    @category_queries = []
  end

  def pages(titles)
    @page_queries.concat(titles)
    titles.to_h { |title| [ title, @pages.fetch(title, nil) ] }
  end

  def category_members(category)
    @category_queries << category
    @category_members.fetch(category, [])
  end
end
