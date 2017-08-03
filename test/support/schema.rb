# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

# Every table is a step. In tests, you always go toward the bigger step.
# You can do it using a belongs_to, or has_one/has_many.

ActiveRecord::Schema.define do
  create_table :s0s do |t|
    t.integer :s1_id

    t.bigint :s0s_column
    t.bigint :s0s_adhoc_column
  end

  create_table :s1s do |t|
    t.integer :s0_id
    t.integer :s1_id

    t.bigint :s1s_column
    t.bigint :s1s_adhoc_column
  end

  create_table :s2s do |t|
    t.integer :s1_id
    t.integer :s3_id

    t.bigint :s2s_column
    t.bigint :s2s_adhoc_column
  end

  create_table :s3s do |t|
    t.integer :s2_id

    t.bigint :s3s_column
    t.bigint :s3s_adhoc_column
  end
end
