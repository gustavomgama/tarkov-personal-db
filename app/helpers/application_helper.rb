module ApplicationHelper
  def tk_money(item)
    return nil if item.price.blank?

    "#{number_with_delimiter(Integer(item.price))} #{item.currency}"
  end

  def category_options
    {
      "ammo" => "Ammo",
      "gun" => "Gun",
      "helmet" => "Helmet",
      "armor" => "Armor",
      "armored rig" => "Armored rig",
      "rig" => "Rig",
      "backpack" => "Backpack",
      "headset_earpiece" => "Headset / earpiece",
      "gun_parts" => "Gun parts",
      "wearable_parts" => "Wearable parts",
      "containers" => "Containers",
      "others" => "Others"
    }
  end

  def selected_currencies
    Array(params[:currency]).intersection(%w[RUB USD EUR])
  end

  def sortable_th(column, label)
    active = params[:sort] == column
    next_dir = active && params[:dir] != "desc" ? "desc" : "asc"
    arrow = active ? (params[:dir] == "desc" ? " ▾" : " ▴") : ""
    query = request.query_parameters.merge("sort" => column, "dir" => next_dir, "page" => nil).compact.to_h
    "<th>#{link_to "#{label}#{arrow}", "#{request.path}?#{query.to_query}", class: 'link-accent text-decoration-none'}</th>".html_safe
  end


  def tk_condition_text(condition)
    parts = []
    parts << "Buy · #{condition[:trader]}" if condition[:trader] && condition[:types].include?("money")
    parts << "Barter · #{condition[:trader]}" if condition[:trader] && condition[:types].include?("barter")
    parts << "Craft" if condition[:types].include?("craft") && condition[:trader].blank?
    if condition[:loyalty_cost]
      parts << "LL#{condition[:loyalty]} (level #{condition[:loyalty_cost].required_player_level || "?"}, rep #{condition[:loyalty_cost].required_reputation})"
    elsif condition[:loyalty]
      parts << "LL#{condition[:loyalty]}"
    end
    parts.join(" · ")
  end
end
