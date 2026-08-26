class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  HTTP_LINK = ->(value) { value.to_s.match?(/\Ahttps?:\/\//i) ? value : nil }

  # Every word in +query+ must appear in +attribute+ (case-insensitive, any order).
  def self.token_search(attribute, query)
    tokens = query.to_s.split.reject(&:blank?)
    return all if tokens.empty?

    where(Array.new(tokens.size, "LOWER(#{attribute}) LIKE ?").join(" AND "),
          *tokens.map { |token| "%#{token.downcase}%" })
  end
end
