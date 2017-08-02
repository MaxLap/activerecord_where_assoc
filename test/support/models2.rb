
# frozen_string_literal: true

require_relative "base_test_model"

# Creating a set of classes with the references that go between them.
# Classes are names S0, S1, S2... for "Step"
# Relations are names m0, o2, b3 for "Many", "One", "Belong"
# A class always point further down to the next steps

(0..TESTS_NB_DEPTH).each do |step_id|
  c = Class.new(BaseTestRecord) do
    # A belongs_to to the next step
    if step_id < TESTS_NB_DEPTH
      belongs_to :"b#{step_id + 1}", class_name: "S#{step_id + 1}"
    end

    # A has_many and a has_one to the next step
    if step_id < TESTS_NB_DEPTH
      has_many :"m#{step_id + 1}", class_name: "S#{step_id + 1}"
      has_one :"o#{step_id + 1}", class_name: "S#{step_id + 1}"
    end
  end

  Object::const_set("S#{step_id}", c)
end
