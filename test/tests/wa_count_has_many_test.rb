# frozen_string_literal: true

require "test_helper"

describe "where_assoc_count" do
  let(:s0) { S0.create_default! }

  it "counts every matching has_many" do
    s0
    assert_wa_count(0, :m1)

    s0.create_assoc!(:m1, :S0_m1)
    assert_wa_count(1, :m1)

    s0.create_assoc!(:m1, :S0_m1)
    assert_wa_count(2, :m1)
  end

  it "counts every matching has_many through has_many through has_many" do
    m1_1 = s0.create_assoc!(:m1, :S0_m1)
    m1_2 = s0.create_assoc!(:m1, :S0_m1)

    m2_11 = m1_1.create_assoc!(:m2, :S0_m2m1, :S1_m2)
    m2_12 = m1_1.create_assoc!(:m2, :S0_m2m1, :S1_m2)

    m2_21 = m1_2.create_assoc!(:m2, :S0_m2m1, :S1_m2)
    m2_22 = m1_2.create_assoc!(:m2, :S0_m2m1, :S1_m2)

    m2_11.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)
    m2_11.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)
    m2_12.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)
    m2_12.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)
    m2_21.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)
    m2_21.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)
    m2_22.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)
    m2_22.create_assoc!(:m3, :S0_m3m2m1, :S2_m3)

    assert_wa_count(8, :m3m2m1)
  end

  it "counts every matching has_many through a has_many with a source that is a has_many through" do
    m1_1 = s0.create_assoc!(:m1, :S0_m1)
    m1_2 = s0.create_assoc!(:m1, :S0_m1)

    m2_11 = m1_1.create_assoc!(:m2, :S1_m2)
    m2_12 = m1_1.create_assoc!(:m2, :S1_m2)

    m2_21 = m1_2.create_assoc!(:m2, :S0_m2m1, :S1_m2)
    m2_22 = m1_2.create_assoc!(:m2, :S0_m2m1, :S1_m2)

    m2_11.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)
    m2_11.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)
    m2_12.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)
    m2_12.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)
    m2_21.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)
    m2_21.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)
    m2_22.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)
    m2_22.create_assoc!(:m3, :S0_m3m1_m3m2, :S1_m3m2, :S2_m3)

    assert_wa_count(8, :m3m1_m3m2)
  end
end
