# frozen_string_literal: true

require_relative "../../test_helper"

describe "wa" do
  let(:s0) { S0.create_default! }

  it "finds the right matching poly belongs_to" do
    s0_1 = s0
    s0_1.create_assoc!(:bp1, :S0_bp1, target_model: S1)

    _s0_2 = S0.create_default!

    s0_3 = S0.create_default!
    s0_3.create_assoc!(:bp1, :S0_bp1, target_model: S1)

    _s0_4 = S0.create_default!

    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: :pluck).to_a.sort_by(&:id)
    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: S1).to_a.sort_by(&:id)
    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: [S1]).to_a.sort_by(&:id)
    assert_equal [s0_1, s0_3], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: [S1, S2]).to_a.sort_by(&:id)
    assert_equal [], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: [S2]).to_a.sort_by(&:id)
    assert_equal [], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: []).to_a.sort_by(&:id)
  end

  it "finds a matching poly belongs_to" do
    s0.create_assoc!(:bp1, :S0_bp1, target_model: S1)
    s0.create_assoc!(:bp1, :S0_bp1, target_model: S1)

    assert_wa(1, :bp1, nil, poly_belongs_to: :pluck)
  end

  it "finds a matching poly belongs_to with per model scope" do
    s0.create_assoc!(:bp1, :S0_bp1, target_model: S1)
    s1 = s0.create_assoc!(:bp1, :S0_bp1, target_model: S1)

    s1.update!(s1s_adhoc_column: 42)

    without_manual_wa_test do
      assert_wa(1, :bp1, nil, poly_belongs_to: { S1 => proc { where(s1s_adhoc_column: 42) } })
      assert_wa(1, :bp1, nil, poly_belongs_to: { S1 => { s1s_adhoc_column: 42 } })
      assert_wa(1, :bp1, nil, poly_belongs_to: { S1 => "s1s_adhoc_column = 42" })
    end
  end

  it "doesn't finds a non matching poly belongs_to with per model scope" do
    s0.create_assoc!(:bp1, :S0_bp1, target_model: S1)
    s1 = s0.create_assoc!(:bp1, :S0_bp1, target_model: S1)

    s1.update!(s1s_adhoc_column: 21)

    without_manual_wa_test do
      assert_wa(0, :bp1, nil, poly_belongs_to: { S1 => proc { where(s1s_adhoc_column: 42) } })
      assert_wa(0, :bp1, nil, poly_belongs_to: { S1 => { s1s_adhoc_column: 42 } })
      assert_wa(0, :bp1, nil, poly_belongs_to: { S1 => "s1s_adhoc_column = 42" })
    end
  end

  it "finds a matching recursive poly belongs_to" do
    s0.create_assoc!(:bp1, :S0_bp1, target_model: S0)
    s0.create_assoc!(:bp1, :S0_bp1, target_model: S0)

    assert_equal [s0], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: :pluck).to_a.sort_by(&:id)
    assert_equal [s0], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: S0).to_a.sort_by(&:id)
    assert_equal [s0], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: [S0, S1]).to_a.sort_by(&:id)
    assert_equal [], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: S1).to_a.sort_by(&:id)
  end

  it "finds a matching poly belongs_to with multiple tables" do
    s0_1 = s0
    s0_1.create_assoc!(:bp1, :S0_bp1, target_model: S1)

    s0_2 = S0.create_default!
    s0_2.create_assoc!(:bp1, :S0_bp1, target_model: S2)

    assert_wa(1, :bp1, nil, poly_belongs_to: :pluck)

    _s0_3 = S0.create_default!
    assert_equal [s0_1, s0_2], S0.where_assoc_count(1, :==, :bp1, nil, poly_belongs_to: :pluck).to_a.sort_by(&:id)
  end

  it "doesn't find without any poly belongs_to" do
    s0
    assert_wa(0, :bp1, nil, poly_belongs_to: :pluck)
  end

  it "doesn't find with a non matching poly belongs_to" do
    s0.create_bad_assocs!(:bp1, :S0_bp1, target_model: S1)

    # Manual test will fail when landing on a model that has no table
    without_manual_wa_test do
      assert_wa(0, :bp1, nil, poly_belongs_to: :pluck)
    end
  end

  it "finds a matching has_many :through that uses a poly belongs_to source" do
    s1_1 = s0.create_assoc!(:mp1, :S0_mp1)
    s1_1.create_assoc!(:bp2, :S0_mbp2mp1, :S1_bp2, target_model: S2)

    s1_2 = s0.create_assoc!(:mp1, :S0_mp1)
    s1_2.create_assoc!(:bp2, :S0_mbp2mp1, :S1_bp2, target_model: S2)

    _s1_3 = s0.create_assoc!(:mp1, :S0_mp1)

    # ActiveRecord only handles such relation when they hae a source_type
    # We don't need that because we can pluck for polymorphic belongs_to
    without_manual_wa_test do
      assert_wa(2, :mbp2mp1, nil, poly_belongs_to: :pluck)
      assert_wa(2, :mbp2mp1, nil, poly_belongs_to: [S2])
    end
  end

  it "finds a matching has_many :through that uses a poly belongs_to source and source_type" do
    s1_1 = s0.create_assoc!(:mp1, :S0_mp1)
    s1_1.create_assoc!(:bp2, :S0_mbp2mp1_st, :S1_bp2, target_model: S2)

    s1_2 = s0.create_assoc!(:mp1, :S0_mp1)
    s1_2.create_assoc!(:bp2, :S0_mbp2mp1_st, :S1_bp2, target_model: S2)

    _s1_3 = s0.create_assoc!(:mp1, :S0_mp1)

    # This one doesn't match the source_type, so should be ignored
    s1_4 = s0.create_assoc!(:mp1, :S0_mp1)
    s1_4.create_assoc!(:bp2, :S0_mbp2mp1_st, :S1_bp2, target_model: S3)

    assert_wa(2, :mbp2mp1_st)
  end

  it "finds a matching has_many :through that uses a poly belongs_to source with multiple tables same S0" do
    s1_1 = s0.create_assoc!(:mp1, :S0_mp1)
    s1_1.create_assoc!(:bp2, :S0_mbp2mp1, :S1_bp2, target_model: S2)

    s1_2 = s0.create_assoc!(:mp1, :S0_mp1)
    s1_2.create_assoc!(:bp2, :S0_mbp2mp1, :S1_bp2, target_model: S3)

    _s1_3 = s0.create_assoc!(:mp1, :S0_mp1)

    # ActiveRecord only handles such relation when they hae a source_type
    # We don't need that because we can pluck for polymorphic belongs_to
    without_manual_wa_test do
      assert_wa(2, :mbp2mp1, nil, poly_belongs_to: :pluck)
    end
  end

  it "finds a matching has_many :through that uses a poly belongs_to source with multiple tables different S0" do
    s0_1 = s0
    s1_1 = s0_1.create_assoc!(:mp1, :S0_mp1)
    s1_1.create_assoc!(:bp2, :S0_mbp2mp1, :S1_bp2, target_model: S2)

    s0_2 = S0.create_default!
    s1_2 = s0_2.create_assoc!(:mp1, :S0_mp1)
    s1_2.create_assoc!(:bp2, :S0_mbp2mp1, :S1_bp2, target_model: S3)

    # ActiveRecord only handles such relation when they hae a source_type
    # We don't need that because we can pluck for polymorphic belongs_to
    without_manual_wa_test do
      assert_wa(1, :mbp2mp1, nil, poly_belongs_to: :pluck)
    end

    _s0_3 = S0.create_default!
    assert_equal [s0_1, s0_2], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: :pluck).to_a.sort_by(&:id)
    assert_equal [s0_1], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: S2).to_a.sort_by(&:id)
    assert_equal [s0_1], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: [S0, S2]).to_a.sort_by(&:id)
    assert_equal [s0_1, s0_2], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: [S2, S3]).to_a.sort_by(&:id)
    assert_equal [], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: [S0]).to_a.sort_by(&:id)
    assert_equal [], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: []).to_a.sort_by(&:id)
  end

  it "finds a matching has_many :through that uses a poly belongs_to source and source_type with different S0" do
    s0_1 = s0
    s1_1 = s0_1.create_assoc!(:mp1, :S0_mp1)
    s1_1.create_assoc!(:bp2, :S0_mbp2mp1_st, :S1_bp2, target_model: S2)

    s0_2 = S0.create_default!
    s1_2 = s0_2.create_assoc!(:mp1, :S0_mp1)
    s1_2.create_assoc!(:bp2, :S0_mbp2mp1_st, :S1_bp2, target_model: S2)

    assert_wa(1, :mbp2mp1_st)

    # This one doesn't match the source_type, so should be ignored
    s0_3 = S0.create_default!
    s1_3 = s0_3.create_assoc!(:mp1, :S0_mp1)
    s1_3.create_assoc!(:bp2, :S0_mbp2mp1_st, :S1_bp2, target_model: S3)

    assert_equal [s0_1, s0_2], S0.where_assoc_count(1, :==, :mbp2mp1_st).to_a.sort_by(&:id)
  end

  it "doesn't find has_many through that uses a poly belongs_to source if no :through match" do
    s0
    # ActiveRecord only handles such relation when they hae a source_type
    # We don't need that because we can pluck for polymorphic belongs_to
    without_manual_wa_test do
      assert_wa(0, :mbp2mp1, nil, poly_belongs_to: :pluck)
    end
  end

  it "doesn't find has_many through that uses a poly belongs_to source if no :source match" do
    s1 = s0.create_assoc!(:mp1, :S0_mp1)
    s1.create_bad_assocs!(:bp2, :S0_mbp2mp1, :S1_mp2, target_model: S2)

    # ActiveRecord only handles such relation when they hae a source_type
    # We don't need that because we can pluck for polymorphic belongs_to
    without_manual_wa_test do
      assert_wa(0, :mbp2mp1, nil, poly_belongs_to: :pluck)
    end
  end

  it "finds a matching has_many :through that uses a poly belongs_to source with multiple tables different S0" do
    s0_1 = s0
    s1_1 = s0_1.create_assoc!(:mp1, :S0_mp1)
    p1 = s1_1.create_assoc!(:bp2, :S0_mbp2mp1, :S1_bp2, target_model: S2)
    p1.update!(s2s_adhoc_column: 42)

    s0_2 = S0.create_default!
    s1_2 = s0_2.create_assoc!(:mp1, :S0_mp1)
    p2 = s1_2.create_assoc!(:bp2, :S0_mbp2mp1, :S1_bp2, target_model: S3)
    p2.update!(s3s_adhoc_column: 43)

    _s0_3 = S0.create_default!

    assert_equal [s0_1, s0_2], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: { S2 => { s2s_adhoc_column: 42 },
                                                                                              S3 => { s3s_adhoc_column: 43 },
                                                                                            }).to_a.sort_by(&:id)
    assert_equal [s0_1], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: { S2 => { s2s_adhoc_column: 42 },
                                                                                        S3 => { s3s_adhoc_column: 66 },
                                                                                      }).to_a.sort_by(&:id)
    assert_equal [], S0.where_assoc_count(1, :==, :mbp2mp1, nil, poly_belongs_to: { S2 => { s2s_adhoc_column: 66 },
                                                                                    S3 => { s3s_adhoc_column: 66 },
                                                                                  }).to_a.sort_by(&:id)
  end

  it "find has_many through that uses a poly belongs_to source using an array for the association" do
    s1 = s0.create_assoc!(:mp1, :S0_mp1)
    s1.create_assoc!(:bp2, :S1_bp2, target_model: S2)
    s1.create_assoc!(:bp2, :S1_bp2, target_model: S2)

    assert_wa(1, [:mp1, :bp2], nil, poly_belongs_to: :pluck)
  end

  it "doesn't find has_many through that uses a poly belongs_to source if no :through match using an array for the association" do
    s0
    assert_wa(0, [:mp1, :bp2], nil, poly_belongs_to: :pluck)
  end

  it "doesn't find with a non matching poly belongs_to through poly belongs_to using an array for the association" do
    s1 = s0.create_assoc!(:mp1, :S0_mp1)
    s1.create_bad_assocs!(:bp2, :S1_bp2, target_model: S2)

    # Manual test will fail when landing on a model that has no table, which is one of the cases of create_bad_assocs!
    without_manual_wa_test do
      assert_wa(0, [:mp1, :bp2], nil, poly_belongs_to: :pluck)
    end
  end

  it "walks through polymorphic association when given :pluck" do
    s1 = s0.create_assoc!(:bp1, :S0_bp1, target_model: S1)
    s2 = s1.create_assoc!(:bp2, :S1_bp2, target_model: S2)
    assert_wa(0, [:bp1, :bp2, :bp3], nil, poly_belongs_to: :pluck)

    s2.create_assoc!(:bp3, :S2_bp3, target_model: S3)
    assert_wa(1, [:bp1, :bp2, :bp3], nil, poly_belongs_to: :pluck)
  end
end
