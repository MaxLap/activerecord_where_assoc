# frozen_string_literal: true

module AssociationGenie
  # m5m4m3m2m2m1
  # m5m3m1_m5m4_m3m2
  def self.split_assoc(association_name)
    association_name = association_name.to_s
    raise "Wrong association: #{association_name}" unless valid_assoction_name?(association_name)
    groups = association_name.split("_")

    current_group = groups.first
    remaining_groups = groups[1..-1]

    current_parts = split_group(current_group)

    current_part = current_parts.first

    through_parts = [current_parts[1..-1].join]

    source_parts, extra_through_parts = remaining_groups.partition { |rg| rg.include?(current_part) }
    through_parts += extra_through_parts

    puts "th: #{through_parts.join('_')}"
    puts "sr: #{source_parts.join('_')}"
    # has_many current_parts.first, through: current_parts[1..-1]
  end

  def self.valid_assoction_name?(association_name)
    association_name.match(/[mob]\d+(_[mob]\d+)*/)
  end

  def self.split_group(group)
    group.scan(/[mob]\d+/)
  end
end

AG = AssociationGenie
