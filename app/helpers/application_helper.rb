module ApplicationHelper
  def tk_money(item)
    return nil if item.price.blank?

    "#{number_with_delimiter(Integer(item.price))} #{item.currency}"
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
