# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  let(:s0) { STIS0.create! }

  it "belongs_to finds with STI type of same class" do
    s0.create_b1!
    s0.create_b1!
    s0.save! # Save the changed id

    assert_wa_from(STIS0, 1, :b1)
  end
  it "belongs_to finds with STI type of subclass" do
    s0.create_b1sub!
    s0.create_b1sub!
    s0.save! # Save the changed id

    assert_wa_from(STIS0, 1, :b1)
  end
  it "belongs_to doesn't find with STI type of superclass" do
    s0.create_b1!
    s0.create_b1!
    s0.save! # Save the changed id

    assert_wa_from(STIS0, 0, :b1sub)
  end

  it "has_one works with STI type of same class" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0.create_has_one!(:o1)
    s0.create_has_one!(:o1)

    assert_wa_from(STIS0, 1, :o1)
  end
  it "has_one works with STI type of subclass" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0.create_has_one!(:o1sub)
    s0.create_has_one!(:o1sub)

    assert_wa_from(STIS0, 1, :o1)
  end
  it "has_one works with STI type of superclass" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0.create_has_one!(:o1)
    s0.create_has_one!(:o1)

    assert_wa_from(STIS0, 0, :o1sub)
  end

  it "has_many works with STI type of same class" do
    s0.m1.create!
    s0.m1.create!

    assert_wa_from(STIS0, 2, :m1)
  end
  it "has_many works with STI type of subclass" do
    s0.m1sub.create!
    s0.m1sub.create!

    assert_wa_from(STIS0, 2, :m1)
  end
  it "has_many works with STI type of superclass" do
    s0.m1.create!
    s0.m1.create!

    assert_wa_from(STIS0, 0, :m1sub)
  end

  it "has_and_belongs_to_many works with STI type of same class" do
    s0.z1.create!
    s0.z1.create!

    assert_wa_from(STIS0, 2, :z1)
  end
  it "has_and_belongs_to_many works with STI type of subclass" do
    s0.z1sub.create!
    s0.z1sub.create!

    assert_wa_from(STIS0, 2, :z1)
  end
  it "has_and_belongs_to_many works with STI type of superclass" do
    s0.z1.create!
    s0.z1.create!

    assert_wa_from(STIS0, 0, :z1sub)
  end

  it "polymorphic has_many works when defined and used from a root STI class" do
    s0
    assert_wa_from(STIS0, 0, :mp1)
    s0.mp1.create!
    s0.mp1.create!
    assert_wa_from(STIS0, 2, :mp1)
  end
  it "polymorphic has_many works when defined on root STI class and used from a subclass" do
    s0 = STIS0Sub.create!
    assert_wa_from(STIS0, 0, :mp1)
    assert_wa_from(STIS0Sub, 0, :mp1)
    s0.mp1.create
    s0.mp1.create
    assert_wa_from(STIS0, 2, :mp1)
    assert_wa_from(STIS0Sub, 2, :mp1)
  end
  it "polymorphic has_many works when defined and used on the same STI subclass" do
    s0 = STIS0Sub.create!
    assert_wa_from(STIS0Sub, 0, :mp1_from_sub)
    s0.mp1_from_sub.create
    s0.mp1_from_sub.create
    assert_wa_from(STIS0Sub, 2, :mp1_from_sub)
  end
  it "polymorphic has_many works when defined on an STI subclass and used from a deeper subclass" do
    s0 = STIS0SubSub.create!
    assert_wa_from(STIS0SubSub, 0, :mp1_from_sub)
    s0.mp1_from_sub.create
    s0.mp1_from_sub.create
    assert_wa_from(STIS0SubSub, 2, :mp1_from_sub)
  end


  it "polymorphic has_one works when defined and used from a root STI class" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0
    assert_wa_from(STIS0, 0, :op1)
    s0.create_has_one!(:op1)
    s0.create_has_one!(:op1)
    assert_wa_from(STIS0, 1, :op1)
  end
  it "polymorphic has_one works when defined on root STI class and used from a subclass" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0 = STIS0Sub.create!
    assert_wa_from(STIS0, 0, :op1)
    assert_wa_from(STIS0Sub, 0, :op1)
    s0.create_has_one!(:op1)
    s0.create_has_one!(:op1)
    assert_wa_from(STIS0, 1, :op1)
    assert_wa_from(STIS0Sub, 1, :op1)
  end
  it "polymorphic has_one works when defined and used on the same STI subclass" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0 = STIS0Sub.create!
    assert_wa_from(STIS0Sub, 0, :op1_from_sub)
    s0.create_has_one!(:op1)
    s0.create_has_one!(:op1)
    assert_wa_from(STIS0Sub, 1, :op1_from_sub)
  end
  it "polymorphic has_one works when defined on an STI subclass and used from a deeper subclass" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0 = STIS0SubSub.create!
    assert_wa_from(STIS0SubSub, 0, :op1_from_sub)
    s0.create_has_one!(:op1)
    s0.create_has_one!(:op1)
    assert_wa_from(STIS0SubSub, 1, :op1_from_sub)
  end

  it "polymorphic belongs_to to a STI top class works the same as in ActiveRecord" do
    s0
    assert_wa_from(STIS0, 0, :bp1, nil, poly_belongs_to: :pluck)
    s1 = STIS1.create!
    s0.bp1 = s1
    s0.save!
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: :pluck)
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: [STIS1])
    # Using such a subclass like that is basically a condition which we don't compare in manual testing
    without_manual_wa_test do
      assert_wa_from(STIS0, 0, :bp1, nil, poly_belongs_to: [STIS1Sub])
      assert_wa_from(STIS0, 0, :bp1, nil, poly_belongs_to: [STIS1SubSub])
    end
  end

  it "polymorphic belongs_to to a STI single subclass works the same as in ActiveRecord" do
    s0
    assert_wa_from(STIS0, 0, :bp1, nil, poly_belongs_to: :pluck)
    s1 = STIS1Sub.create!
    s0.bp1 = s1
    s0.save!
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: :pluck)
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: [STIS1])
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: [STIS1Sub])
    # Using such a subclass like that is basically a condition which we don't compare in manual testing
    without_manual_wa_test do
      assert_wa_from(STIS0, 0, :bp1, nil, poly_belongs_to: [STIS1SubSub])
    end
  end

  it "polymorphic belongs_to to a STI double subclass works the same as in ActiveRecord" do
    s0
    assert_wa_from(STIS0, 0, :bp1, nil, poly_belongs_to: :pluck)
    s1 = STIS1SubSub.create!
    s0.bp1 = s1
    s0.save!
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: :pluck)
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: [STIS1])
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: [STIS1Sub])
    assert_wa_from(STIS0, 1, :bp1, nil, poly_belongs_to: [STIS1SubSub])
  end
end
