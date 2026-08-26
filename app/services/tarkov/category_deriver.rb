module Tarkov
  # Maps upstream item payloads onto our canonical acquisition categories.
  # Presets inherit the base item's identity via longest normalizedName prefix;
  # armored rigs and containers use name/type heuristics because the upstream
  # type list does not distinguish them.
  class CategoryDeriver
    CANONICAL = %w[ammo gun helmet armor armored\ rig rig backpack
                   headset_earpiece gun_parts wearable_parts containers others].freeze

    def initialize(items_by_normalized_name)
      @by_name = items_by_normalized_name.transform_values { |v| v.is_a?(Array) ? v : [ v ] }
    end

    def derive(attrs)
      types = types_for(attrs)
      name = attrs["normalizedName"].to_s
      categories = []
      categories << "ammo" if (%w[ammo ammoBox] & types).any?
      categories << "gun" if types.include?("gun")
      categories << "helmet" if types.include?("helmet")
      categories << "armor" if types.include?("armor")
      categories << (armored_rig?(types, name) ? "armored rig" : "rig") if types.include?("rig")
      categories << "backpack" if types.include?("backpack")
      categories << "headset_earpiece" if types.include?("headphones")
      categories << "medical" if (%w[meds injectors] & types).any?
      categories << "grenades" if types.include?("grenade")
      categories << "provisions" if types.include?("provisions")
      categories << "gun_parts" if (%w[mods pistolGrip suppressor] & types).any?
      categories << "wearable_parts" if plate_or_wearable?(types, categories)
      categories << "containers" if types.include?("container") || secure_container?(name)
      categories.empty? ? [ "others" ] : categories.uniq
    end

    private

    # Upstream types mark secure containers only as ["noFlea"]; the name is the
    # reliable signal.
    def secure_container?(normalized_name)
      normalized_name.start_with?("secure-container-")
    end

    def types_for(attrs)
      return attrs["types"].to_a unless attrs["types"].to_a.include?("preset")

      base = base_for(attrs["normalizedName"].to_s)
      base ? base["types"].to_a : attrs["types"].to_a
    end

    def base_for(preset_name)
      @by_name.each_value do |candidates|
        candidates.each do |candidate|
          next if candidate["types"].to_a.include?("preset")

          candidate_name = candidate["normalizedName"].to_s
          return candidate if candidate_name.length < preset_name.length &&
                              preset_name.start_with?(candidate_name)
        end
      end
      nil
    end

    def armored_rig?(types, name)
      types.include?("armor") || name.include?("armored")
    end

    def plate_or_wearable?(types, categories)
      return true if types.include?("armorPlate")

      types.include?("wearable") &&
        (categories.include?("headset_earpiece") || gear_free?(categories))
    end

    def gear_free?(categories)
      (categories & %w[gun helmet armor armored\ rig rig backpack]).empty?
    end
  end
end
