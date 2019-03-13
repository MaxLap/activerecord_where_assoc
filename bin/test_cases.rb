
# Scoping on the association
# Default scopes
# Conditions received by hash, array, string, block
# limit / offset (includes has_one's forced limit of one)
# target association is STI
# is from an STI
# schema

<<-IDEA

1- Define a model
  * Does the model have a default_scope
  * Is the model a STI
    If yes, are we at the top level, 1 level down, or 2 level down
  * Does the table_name use a schema
  * limit/offset in default scope

2- Define the association
  * belongs_to, has_many, has_one, habtm
  * is there a condition on the association
    using a same-name column and a different per level name (So ensure no clash)
  * is there a limit/offset on the association
  * is the association polymorphic
  * is the association recursive?
  
3- Define the association's taret model
  (Same as 1-)
  * Can also be a model from a previous step or a variation
  * There can be more than one if association is polymorphic
  * There can be more than one if each is STI

4- More association or finalize?
  * Can either add another association (go to step 2)
    or
    Finalize (go to step 5)
5-Maybe turn chains into :through
  * This can make either a has_many or a has_one
  * there can be a condition on the association
  * there can be a limit
6- Add condition to remaining associations to specify
  * Either either a block or a value

IDEA


TestState = Struct.new(:models, :assocs, :queries) do
  def self.new_blank
    new([], [], [])
  end

  def next_model_id
    (models.map(&:id).max || -1) + 1
  end

  def next_prime_id
    prime_ids = models.map(&:condition_prime_id)
    (prime_ids.max || -1) + 1
  end
end

ModelDetails = Struct.new(:id, :sti_level, :schema_name, :limit, :offset, :order, :condition_prime_id) do
  def self.generate_options(test_state)
    return enum_for(__method__, test_state) unless block_given?

    test_state.models.each { |m| yield m }

    model_id = test_state.next_model_id
    prime_id = test_state.next_prime_id

    # Nothing interesting from using same Schema twice, but there is something interesting from different schemas
    possible_schemas = test_state.models.any?(&:schema_name) ? [nil, :my_schema_1] : [nil, :my_schema_2]

    [nil, 0, 1, 2].each do |sti_level|
      possible_schemas.each do |schema_name|
        [nil, 3].each do |limit|
          possible_offsets = limit ? [nil, 2] : [nil]
          possible_offsets.each do |offset|
            possible_orders = limit ? [nil, :ASC, :DESC] : [nil]
            possible_orders.each do |order|
              [nil, prime_id].each do |condition_prime_id|
                yield new(model_id, sti_level, schema_name, limit, offset, order, condition_prime_id)
              end
            end
          end
        end
      end
    end
  end
end

AssocDetails = Struct.new(:on_model, :macro, :polymorphic, :limit, :offset, :order, :condition_prime_id) do
  def self.generate_options(test_state)
    return enum_for(__method__, test_state) unless block_given?

    prime_id = test_state.next_prime_id

    [:belongs_to, :has_many, :has_one, :habtm].each do |macro|
      [false, true].each do |polymorphic|
        [nil, 2].each do |limit|
          possible_offsets = limit ? [nil, 3] : [nil]
          possible_offsets.each do |offset|
            possible_orders = limit || offset ? [nil, :ASC, :DESC] : [nil]
            possible_orders.each do |order|
              [nil, prime_id].each do |condition_prime_id|
                new(macro, polymorphic, limit, offset, order, condition_prime_id)
              end
            end
          end
        end
      end
    end
  end
end

QueryDetails = Struct.new(:specified_assocs, :given_scope, :given_block) do

end


