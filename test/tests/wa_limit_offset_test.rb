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

    without_manual_wa_test do # ActiveRecord doesn't ignore offset for belongs_to...
      s0.create_b1!
      s0.save!
      assert_wa_from(LimOffOrdS0, 1, :b1)
      assert_wa_from(LimOffOrdS0, 1, :bl1)

      s0.create_b1!
      s0.save!
      assert_wa_from(LimOffOrdS0, 1, :b1)
      assert_wa_from(LimOffOrdS0, 1, :bl1)
    end
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

  # Classes for the following tests only
  class LimThroughS0 < ActiveRecord::Base
    self.table_name = "s0s"
    has_many :m1, class_name: "LimThroughS1", foreign_key: "s0_id"
    has_many :limited_m2m1, -> { limit(2).reorder("s2s.id desc") }, class_name: "LimThroughS2", through: :m1, source: :m2
  end

  class LimThroughS1 < ActiveRecord::Base
    self.table_name = "s1s"
    has_many :m2, class_name: "LimThroughS2", foreign_key: "s1_id"
  end

  class LimThroughS2 < ActiveRecord::Base
    self.table_name = "s2s"
  end

  it "_* ignores limit from has_many :through's scope" do
    s0 = LimThroughS0.create!
    s1 = s0.m1.create!
    s1.m2.create!
    s1.m2.create!
    s1.m2.create!

    without_manual_wa_test do # Different handling of limit on :through associations
      assert_wa_from(LimThroughS0, 3, :limited_m2m1)
    end
  end


  # Classes for the following tests only
  class OffThroughS0 < ActiveRecord::Base
    self.table_name = "s0s"
    has_many :m1, class_name: "OffThroughS1", foreign_key: "s0_id"
    has_many :offset_m2m1, -> { offset(2).reorder("s2s.id desc") }, class_name: "OffThroughS2", through: :m1, source: :m2
  end

  class OffThroughS1 < ActiveRecord::Base
    self.table_name = "s1s"
    has_many :m2, class_name: "OffThroughS2", foreign_key: "s1_id"
  end

  class OffThroughS2 < ActiveRecord::Base
    self.table_name = "s2s"
  end

  it "_* ignores offset from has_many :through's scope" do
    s0 = OffThroughS0.create!
    s1 = s0.m1.create!
    s1.m2.create!
    without_manual_wa_test do # Different handling of offset on :through associations
      assert_wa_from(OffThroughS0, 1, :offset_m2m1)
    end
  end
end
