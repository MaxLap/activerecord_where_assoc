# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :username, null: false
    t.boolean :is_admin, default: false, null: false

    t.timestamps
  end

  create_table :posts do |t|
    t.references :author
    t.text :title
    t.text :content

    t.timestamps
  end

  create_table :comments do |t|
    t.references :author
    t.references :post
    t.text :content
    t.boolean :is_spam, default: false, null: false
    t.boolean :is_reported, default: false, null: false

    t.timestamps
  end
end
