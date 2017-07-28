# frozen_string_literal: true

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :test_models do |t|
    t.integer :test_models_column
  end

  create_table :hms do |t|
    t.integer :test_model_id
    t.integer :hms_column
  end

  create_table :hm_through_hms do |t|
    t.integer :hm_id
    t.integer :hm_through_hms_column
  end

  create_table :hm_through_hm_through_hms do |t|
    t.integer :hm_through_hm_id
    t.integer :hm_through_hm_through_hms_column
  end

  create_table :hm_through_hm_with_through_hm_sources do |t|
    t.integer :hm_through_hm_id
    t.integer :hm_through_hm_with_through_hm_sources_column
  end
end
