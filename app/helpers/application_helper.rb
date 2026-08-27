module ApplicationHelper
  def tk_money(item)
    return nil if item.price.blank?

    "#{number_with_delimiter(Integer(item.price))} #{item.currency}"
  end

  def category_options
    Item::CATEGORIES
  end

  def selected_currencies
    Array(params[:currency]).intersection(%w[RUB USD EUR])
  end

  def per_options
    SortablePaginatable::PER_OPTIONS
  end

  # ---- images -------------------------------------------------------------

  # Serves the locally downloaded copy when tarkov:images has fetched it;
  # falls back to the remote URL until then.
  def item_icon(item)
    image = local_image("items", item.tid, "-icon") || item.icon_link.presence
    return unless image

    image_tag image, width: 30, height: 30, loading: "lazy", alt: "",
              class: "row-icon", data: img_fallback_data
  end

  def item_hero(item)
    url = local_image("items", item.tid) ||
          (item.image_link.presence || item.icon_link.presence)
    return unless url

    image_tag url, class: "item-hero-img rounded border border-secondary", alt: item.name,
              loading: "lazy", data: img_fallback_data
  end

  def ingredient_icon(ingredient)
    image = local_image("items", ingredient["tid"], "-icon") ||
            ingredient["icon_link"].presence
    return unless image

    image_tag image, width: 24, height: 24, loading: "lazy", alt: ingredient["name"].to_s,
              class: "ing-icon", title: ingredient["name"], data: img_fallback_data
  end

  def trader_avatar(trader_or_name, size: 32)
    if trader_or_name.is_a?(Trader)
      return initial_chip(trader_or_name.name, size) if trader_or_name.image_url.blank?

      src = local_image("traders", trader_or_name.tid) || trader_or_name.image_url
      return image_tag src, width: size, height: size, loading: "lazy",
                           class: "trader-avatar", alt: "#{trader_or_name.name} portrait", data: img_fallback_data
    end

    name = trader_or_name.to_s
    initial_chip(name, size)
  end

  # ---- links --------------------------------------------------------------

  # Every trader name shown anywhere is a link to its page.
  def trader_link(trader_or_name, **options)
    trader = trader_or_name.is_a?(Trader) ? trader_or_name : Trader.find_by(name: trader_or_name)
    name = trader&.name || trader_or_name.to_s
    return tag.span(name) unless trader

    link_to name, trader_path(trader), options
  end

  def dev_item_link(item)
    external_link("tarkov.dev ↗", "https://tarkov.dev/item/#{item.slug}") if item.slug.present?
  end

  def dev_task_link(task)
    external_link("tarkov.dev ↗", "https://tarkov.dev/task/#{task.slug}") if task.slug.present?
  end

  def dev_trader_link(trader)
    slug = trader.slug || trader.name.parameterize
    external_link("tarkov.dev ↗", "https://tarkov.dev/trader/#{slug}")
  end

  def external_link(label, url)
    link_to label, url, class: "btn btn-sm btn-outline-secondary", target: "_blank", rel: "noopener"
  end

  def sortable_th(column, label)
    active = params[:sort] == column
    next_dir = active && params[:dir] != "desc" ? "desc" : "asc"
    arrow = active ? (params[:dir] == "desc" ? " ▾" : " ▴") : ""
    query = request.query_parameters.merge("sort" => column, "dir" => next_dir, "page" => nil).compact
    link = link_to "#{label}#{arrow}", "#{request.path}?#{query.to_query}", class: "link-accent text-decoration-none"
    aria_sort = active ? (params[:dir] == "desc" ? "descending" : "ascending") : nil
    tag.th link, "aria-sort": aria_sort
  end

  OFFER_VERBS = { "money" => "Buy from", "barter" => "Barter at", "craft" => "Craft at" }.freeze

  # Upstream GP-coin counts are RUB valuations (e.g. 16.86 coins), not real
  # quantities - showing them would mislead. The icon alone communicates it.
  GP_COIN_TID = "5d235b4d86f7742e017bc88a"

  def gp_coin?(ingredient)
    ingredient["tid"] == GP_COIN_TID || ingredient["name"].to_s.include?("GP coin")
  end

  # Badge color + label for an acquisition offer. GP-coin purchases are
  # Ref-only buys paid with Arena currency - never plain barters.
  def offer_badge(offer)
    if offer[:gp_currency] || gp_payment?(offer)
      %w[accent GP COINS]
    elsif offer[:type] == "reward"
      %w[accent REWARD]
    else
      kind, label = { "money" => %w[success BUY], "barter" => %w[info BARTER],
                      "craft" => %w[primary CRAFT] }.fetch(offer[:type], [ "secondary", offer[:type].upcase ])
      [ kind, label ]
    end
  end

  def gp_payment?(offer)
    offer[:type] == "barter" &&
      Array(offer[:required_items]).any? { |ing| ing["tid"] == GP_COIN_TID }
  end

  def offer_verb(type)
    OFFER_VERBS.fetch(type, "Get from")
  end

  BOOLEAN_FILTER_LABELS = {
    "barter" => "Barter",
    "gp" => "GP (Ref)",
    "craft" => "Craft",
    "unlocked" => "Task-gated",
    "kappa" => "Kappa required"
  }.freeze

  # Active-filter chips for index pages: one removable badge per set param,
  # plus a "clear all" link. +keys+ selects which params to surface.
  def filter_chips(*keys)
    qp = request.query_parameters
    chips = []
    chips << filter_chip("Search: #{qp[:q]}", q: nil) if keys.delete("q") && qp[:q].present?
    if keys.delete("trader_id") && qp[:trader_id].present?
      name = Trader.where(id: qp[:trader_id]).pick(:name) || "Trader ##{qp[:trader_id]}"
      chips << filter_chip(name, trader_id: nil)
    end
    if keys.delete("currency")
      Array(qp[:currency]).each do |value|
        chips << filter_chip(value, currency: Array(qp[:currency]) - [ value ])
      end
    end
    if keys.delete("categories")
      Array(qp[:categories]).each do |value|
        label = Item::CATEGORIES.fetch(value, value)
        changes = { categories: Array(qp[:categories]) - [ value ] }
        chips << filter_chip(label, changes)
      end
    end
    keys.each do |key|
      next unless qp[key] == "1"

      chips << filter_chip(BOOLEAN_FILTER_LABELS.fetch(key, key.humanize), key => nil)
    end
    return "" if chips.empty?

    safe_join([ tag.span("Filters", class: "tk-label mb-0"), *chips,
                link_to("Clear all", request.path, class: "link-secondary small text-decoration-none") ], " ")
  end

  private

  LOCAL_IMAGE_CACHE = {}

  def local_image(dir, tid, suffix = "")
    key = "#{dir}/#{tid}#{suffix}"
    return LOCAL_IMAGE_CACHE[key] if LOCAL_IMAGE_CACHE.key?(key)

    path = Dir[Rails.root.join("public/images/#{dir}/#{tid}#{suffix}.*")].first
    LOCAL_IMAGE_CACHE[key] = path ? "/images/#{dir}/#{File.basename(path)}" : nil
  end

  def img_fallback_data
    { controller: "img-fallback", action: "error->img-fallback#error" }
  end

  def initial_chip(name, size = 32)
    tag.span((name.to_s[0] || "?").upcase, class: "trader-avatar trader-avatar-fallback",
                                            style: "width:#{size}px;height:#{size}px;line-height:#{size - 2}px;")
  end

  def filter_chip(label, changes)
    query = request.query_parameters.merge(changes.transform_keys(&:to_s)).compact_blank
    query = query.except("page")
    link_to "#{label} ✕", "#{request.path}?#{query.to_query}",
            class: "badge text-bg-secondary p-2 text-decoration-none fw-normal"
  end
end
