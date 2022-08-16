# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  let(:s0) { STIS0.create! }

  it "belongs_to on abstract model works on its descendant" do
    a = UnabstractModel.create!

    a.create_b1!(never_abstracted_models_column: 42)
    a.save!
    assert_wa_from(UnabstractModel, 1, :b1, never_abstracted_models_column: 42)
    assert_wa_from(UnabstractModel, 0, :b1, never_abstracted_models_column: 43)
  end

  it "has_one on abstract model works on its descendant" do
    skip if Test::SelectedDBHelper == Test::MySQL

    a = UnabstractModel.create!

    a.create_o1!(never_abstracted_models_column: 42)

    assert_wa_from(UnabstractModel, 1, :o1, never_abstracted_models_column: 42)
    assert_wa_from(UnabstractModel, 0, :o1, never_abstracted_models_column: 43)
  end

  it "has_many on abstract model works on its descendant" do
    a = UnabstractModel.create!

    a.m1.create!(never_abstracted_models_column: 42)
    a.m1.create!(never_abstracted_models_column: 42)

    assert_wa_from(UnabstractModel, 2, :m1, never_abstracted_models_column: 42)
    assert_wa_from(UnabstractModel, 0, :m1, never_abstracted_models_column: 43)
  end


  it "polymorphic has_many on abstract model works on its descendant" do
    a = UnabstractModel.create!

    a.mp1.create!(never_abstracted_models_column: 42)
    a.mp1.create!(never_abstracted_models_column: 42)

    assert_wa_from(UnabstractModel, 2, :mp1, never_abstracted_models_column: 42)
    assert_wa_from(UnabstractModel, 0, :mp1, never_abstracted_models_column: 43)
  end

  it "polymorphic has_one on abstract model works on its descendant" do
    skip if Test::SelectedDBHelper == Test::MySQL

    a = UnabstractModel.create!

    a.create_has_one!(:op1, never_abstracted_models_column: 42)
    a.create_has_one!(:op1, never_abstracted_models_column: 42)

    assert_wa_from(UnabstractModel, 1, :op1, never_abstracted_models_column: 42)
    assert_wa_from(UnabstractModel, 0, :op1, never_abstracted_models_column: 43)
  end

  it "polymorphic belongs_to on abstract model works on its descendant with poly_belongs_to: :pluck" do
    a = UnabstractModel.create!
    b = NeverAbstractedModel.create!(never_abstracted_models_column: 42)
    a.bp1 = b
    a.save!

    assert_wa_from(UnabstractModel, 1, :bp1, {never_abstracted_models_column: 42}, poly_belongs_to: :pluck)
    assert_wa_from(UnabstractModel, 0, :bp1, {never_abstracted_models_column: 43}, poly_belongs_to: :pluck)
  end

  it "polymorphic belongs_to on abstract model works on its descendant with poly_belongs_to: Class" do
    a = UnabstractModel.create!
    b = NeverAbstractedModel.create!(never_abstracted_models_column: 42)
    a.bp1 = b
    a.save!

    assert_wa_from(UnabstractModel, 1, :bp1, {never_abstracted_models_column: 42}, poly_belongs_to: NeverAbstractedModel)
    assert_wa_from(UnabstractModel, 0, :bp1, {never_abstracted_models_column: 43}, poly_belongs_to: NeverAbstractedModel)
  end
end
