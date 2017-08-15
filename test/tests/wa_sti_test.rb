# frozen_string_literal: true

require "test_helper"

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
    s0.create_o1!
    s0.create_o1!

    assert_wa_from(STIS0, 1, :o1)
  end
  it "has_one works with STI type of subclass" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0.create_o1sub!
    s0.create_o1sub!

    assert_wa_from(STIS0, 1, :o1)
  end
  it "has_one works with STI type of superclass" do
    skip if Test::SelectedDBHelper == Test::MySQL
    s0.create_o1!
    s0.create_o1!

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
end
