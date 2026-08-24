class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Every word in +query+ must appear in +attribute+ (case-insensitive, any order).
  def self.token_search(attribute, query)
    query.to_s.split.reject(&:blank?)
        .inject(all) { |scope, token| scope.where("LOWER(#{attribute}) LIKE ?", "%#{token.downcase}%") }
  end
end
