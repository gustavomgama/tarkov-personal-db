module Tarkov
  # Display-name lookups from json.tarkov.dev localization files ({entity}_{lang}).
  # Entity payloads carry "<tid> Name" placeholders; these dictionaries map those
  # exact strings to real display names, so the wiki is never needed for naming.
  class Localizations
    def initialize(items: {}, tasks: {}, traders: {})
      @items = items
      @tasks = tasks
      @traders = traders
    end

    def item_name(tid)
      @items["#{tid} Name"]
    end

    def item_short_name(tid)
      @items["#{tid} ShortName"]
    end

    def task_name(tid)
      @tasks["#{tid} name"]
    end

    def trader_nickname(tid)
      @traders["#{tid} Nickname"]
    end
  end
end
