# frozen_string_literal: true

require_relative "../test_helper"

# Last Equality Wins is a special behavior in rails since 4.0
# https://github.com/rails/rails/issues/7365
#
# Basically, when using #merge, if the receiving relation has a hash
# condition on an attribute and the passed relation also has one on
# the same attribute with a different value, only the value of the
# passed relation will be kept.
#
# In rails, this behavior is only applied in one situation: When an
# association on a model has a scope and the target model has a
# default_scope. In that situation, the association's scope wins.
#
# We need to make sure this happens in our system too.

describe "wa" do
  let(:s0) { LEWS0.create! }

  it "finds a matching belongs_to (LEW) that has the value of the association's scope" do
    s0.create_b1!(lew_s1s_column: "belongs_to")
    # need to save the changed column
    s0.save!

    assert_wa_from(LEWS0, 1, :b1)
  end

  it "doesn't find a belongs_to (LEW) that has the value of the model's default_scope" do
    s0.create_b1(lew_s1s_column: "default_scope")
    # need to save the changed column
    s0.save!

    assert_wa_from(LEWS0, 0, :b1)
  end

  it "finds a matching has_and_belongs_to_many (LEW) that has the value of the association's scope" do
    s0.z1.create!(lew_s1s_column: "habtm")
    s0.z1.create!(lew_s1s_column: "habtm")
    s0.z1.create!(lew_s1s_column: "default_scope")
    s0.z1.create!(lew_s1s_column: "none")

    assert_wa_from(LEWS0, 2, :z1)
  end

  it "doesn't find a has_and_belongs_to_many (LEW) that has the value of the model's default_scope" do
    s0.z1.create!(lew_s1s_column: "default_scope")
    s0.z1.create!(lew_s1s_column: "none")

    assert_wa_from(LEWS0, 0, :z1)
  end

  it "finds a matching has_many (LEW) that has the value of the association's scope" do
    s0.m1.create!(lew_s1s_column: "has_many")
    s0.m1.create!(lew_s1s_column: "has_many")
    s0.m1.create!(lew_s1s_column: "default_scope")
    s0.m1.create!(lew_s1s_column: "none")

    assert_wa_from(LEWS0, 2, :m1)
  end

  it "doesn't find a has_many (LEW) that has the value of the model's default_scope" do
    s0.m1.create!(lew_s1s_column: "default_scope")
    s0.m1.create!(lew_s1s_column: "none")

    assert_wa_from(LEWS0, 0, :m1)
  end

  it "finds a matching has_one (LEW) that has the value of the association's scope" do
    skip if Test::SelectedDBHelper == Test::MySQL

    s0.create_o1!(lew_s1s_column: "has_one")
    s0.create_o1!(lew_s1s_column: "has_one")
    s0.create_o1!(lew_s1s_column: "default_scope")
    s0.create_o1!(lew_s1s_column: "none")
    # #create of has_one will unlink the existing one
    LEWS1.unscoped.update_all(lew_s0_id: s0.id)

    assert_wa_from(LEWS0, 1, :o1)
  end

  it "doesn't find a has_one (LEW) that has the value of the model's default_scope" do
    skip if Test::SelectedDBHelper == Test::MySQL

    s0.create_o1(lew_s1s_column: "default_scope")
    s0.create_o1(lew_s1s_column: "none")
    # #create of has_one will unlink the existing one
    LEWS1.unscoped.update_all(lew_s0_id: s0.id)

    assert_wa_from(LEWS0, 0, :o1)
  end
end
