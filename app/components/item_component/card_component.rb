# frozen_string_literal: true

module ItemComponent
  class CardComponent < ViewComponent::Base
    attr_reader :item

    def initialize(item:)
      super
      @item = item
    end

    def image_url
      item.images.first || "https://via.placeholder.com/150"
    end

    def category_badges
      item.categories.first(3)
    end
  end
end
