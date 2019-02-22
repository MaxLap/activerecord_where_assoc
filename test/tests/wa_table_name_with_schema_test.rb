# frozen_string_literal: true

require_relative "../test_helper"

describe "wa" do
  next if Test::SelectedDBHelper == Test::SQLite3
  describe "from a schema table" do
    let(:s0) { SchemaS0.create! }

    describe "to a schema table" do
      it "belongs_to works" do
        s0.create_schema_b1!
        s0.save! # Save the changed id

        assert_wa_from(SchemaS0, 1, :schema_b1)
      end

      it "has_one works" do
        skip if Test::SelectedDBHelper == Test::MySQL

        s0.create_has_one!(:schema_o1)

        assert_wa_from(SchemaS0, 1, :schema_o1)
      end

      it "has_many works" do
        s0.schema_m1.create!

        assert_wa_from(SchemaS0, 1, :schema_m1)
      end

      it "has_and_belongs_to_many works" do
        s0.schema_z1.create!

        assert_wa_from(SchemaS0, 1, :schema_z1)
      end
    end

    describe "to a schemaless table" do
      it "belongs_to works" do
        s0.create_assoc!(:b1, nil)

        assert_wa_from(SchemaS0, 1, :b1)
      end

      it "has_one works" do
        skip if Test::SelectedDBHelper == Test::MySQL
        s0.create_assoc!(:o1, nil)

        assert_wa_from(SchemaS0, 1, :o1)
      end

      it "has_many works" do
        s0.create_assoc!(:m1, nil)

        assert_wa_from(SchemaS0, 1, :m1)
      end
    end
  end

  describe "from a schemaless table to a schema table" do
    let(:s0) { S0.create_default! }
    it "belongs_to works" do
      s0.create_schema_b1!
      s0.save! # Save the changed id

      assert_wa_from(S0, 1, :schema_b1)
    end

    it "has_one works" do
      skip if Test::SelectedDBHelper == Test::MySQL

      s0.create_has_one!(:schema_o1)

      assert_wa_from(S0, 1, :schema_o1)
    end

    it "has_many works" do
      s0.schema_m1.create!

      assert_wa_from(S0, 1, :schema_m1)
    end
  end
end
