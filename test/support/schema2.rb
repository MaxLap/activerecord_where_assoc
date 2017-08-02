# frozen_string_literal: true

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  (0..TESTS_NB_DEPTH).each do |i|
    create_table "s#{i}s" do |t|
      # A column to apply conditions
      t.integer "s#{i}s_column"

      # an id for th previous step for has_many and has_one
      if i > 0
        t.integer "s#{i - 1}_id"
      end

      # an id toward the next step for belongs_to
      if i < TESTS_NB_DEPTH
        t.integer "s#{i + 1}_id"
      end
    end
  end
end
