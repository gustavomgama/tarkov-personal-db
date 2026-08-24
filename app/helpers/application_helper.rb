module ApplicationHelper
  def tk_money(item)
    return nil if item.price.blank?

    "#{number_with_delimiter(Integer(item.price))} #{item.currency}"
  end

  def tk_condition_text(condition)
    parts = []
    parts << "Buy from #{condition[:trader]}" if condition[:trader] && condition[:types].include?("money")
    parts << "Barter at #{condition[:trader]}" if condition[:trader] && condition[:types].include?("barter")
    parts << "Craft" if condition[:types].include?("craft")
    text = parts.join(" · ")
    return text if condition[:loyalty_cost].blank?

    text + " — reach Loyalty Level #{condition[:loyalty]} " \
           "(player level #{condition[:loyalty_cost].required_player_level || '?'}, " \
           "rep #{condition[:loyalty_cost].required_reputation})"
  end

  def tk_badges(*items)
    safe_join(items.compact, " ")
  end
end
