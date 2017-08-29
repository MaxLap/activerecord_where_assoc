# frozen_string_literal: true

require "test_helper"

# Since the goal is to check only against the records that would be returned by the association,
# we need to follow the expected behavior for limits, offset and order.

describe "wa" do
  let(:s0) { LimOffOrdS0.create! }

  it "Count with belongs_to handles (ignore) offsets and limit" do
    s0
    assert_wa_from(LimOffOrdS0, 0, :b1)
    assert_wa_from(LimOffOrdS0, 0, :bl1)

    s0.create_b1!
    s0.save!
    assert_wa_from(LimOffOrdS0, 1, :b1)
    assert_wa_from(LimOffOrdS0, 1, :bl1)

    s0.create_b1!
    s0.save!
    assert_wa_from(LimOffOrdS0, 1, :b1)
    assert_wa_from(LimOffOrdS0, 1, :bl1)
  end

  it "Count with has_many follows limits and offsets" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0
    assert_wa_from(LimOffOrdS0, 0, :m1)
    assert_wa_from(LimOffOrdS0, 0, :ml1)

    s0.m1.create!
    assert_wa_from(LimOffOrdS0, 0, :m1)
    assert_wa_from(LimOffOrdS0, 0, :ml1)

    s0.m1.create!
    assert_wa_from(LimOffOrdS0, 1, :m1)
    assert_wa_from(LimOffOrdS0, 0, :ml1)

    s0.m1.create!
    assert_wa_from(LimOffOrdS0, 2, :m1)
    assert_wa_from(LimOffOrdS0, 1, :ml1)

    s0.m1.create!
    assert_wa_from(LimOffOrdS0, 3, :m1)
    assert_wa_from(LimOffOrdS0, 2, :ml1)

    s0.m1.create!
    assert_wa_from(LimOffOrdS0, 3, :m1)
    assert_wa_from(LimOffOrdS0, 2, :ml1)
  end

  it "Count with has_one follows offsets and limit is set to 1" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0
    assert_wa_from(LimOffOrdS0, 0, :o1)
    assert_wa_from(LimOffOrdS0, 0, :ol1)

    s0.create_has_one!(:o1)
    assert_wa_from(LimOffOrdS0, 0, :o1)
    assert_wa_from(LimOffOrdS0, 0, :ol1)

    s0.create_has_one!(:o1)
    assert_wa_from(LimOffOrdS0, 1, :o1)
    assert_wa_from(LimOffOrdS0, 0, :ol1)

    s0.create_has_one!(:o1)
    assert_wa_from(LimOffOrdS0, 1, :o1)
    assert_wa_from(LimOffOrdS0, 1, :ol1)

    s0.create_has_one!(:o1)
    assert_wa_from(LimOffOrdS0, 1, :o1)
    assert_wa_from(LimOffOrdS0, 1, :ol1)
  end

  it "Count with has_and_belongs_to_many follows limits and offsets" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0
    assert_wa_from(LimOffOrdS0, 0, :z1)
    assert_wa_from(LimOffOrdS0, 0, :zl1)

    s0.z1.create!
    assert_wa_from(LimOffOrdS0, 0, :z1)
    assert_wa_from(LimOffOrdS0, 0, :zl1)

    s0.z1.create!
    assert_wa_from(LimOffOrdS0, 1, :z1)
    assert_wa_from(LimOffOrdS0, 0, :zl1)

    s0.z1.create!
    assert_wa_from(LimOffOrdS0, 2, :z1)
    assert_wa_from(LimOffOrdS0, 1, :zl1)

    s0.z1.create!
    assert_wa_from(LimOffOrdS0, 3, :z1)
    assert_wa_from(LimOffOrdS0, 2, :zl1)

    s0.z1.create!
    assert_wa_from(LimOffOrdS0, 3, :z1)
    assert_wa_from(LimOffOrdS0, 2, :zl1)
  end
end
