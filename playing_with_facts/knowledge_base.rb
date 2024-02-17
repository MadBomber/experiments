# experiments/prolog/knowledge_base.rb

require_relative 'fact'

class KnowledgeBase
  # Provides access to @facts for inspection if necessary, but not required per se.
  attr_reader :facts
  
  def initialize
    @facts = []
  end
  
  # Allows direct manipulation of @facts like pushing elements into the array.
  def method_missing(method_name, *args, &block)
    if @facts.respond_to?(method_name)
      @facts.send(method_name, *args, &block)
    else
      super
    end
  end
  
  # Let's Ruby know which methods are handled by method_missing for this object.
  def respond_to_missing?(method_name, include_private = false)
    @facts.respond_to?(method_name, include_private) || super
  end
  
  # Alias for << method to add facts into the KnowledgeBase
  def add(fact)
    self << fact
  end
  

  # a nil entry in a query fact means don't care pr imlmpwm
  def query(query_fact, debug=false)
    q_array = query_fact.to_a

    debug_me{[
      :query_fact,
      :q_array
    ]} if debug

    result  = @facts.select do |fact|
                fact_array = fact.to_a

                debug_me{[
                  :fact,
                  :fact_array,
                  "fact_array.size"
                ]} if debug

                # Check each position in the fact for a match or a nil
                q_array.each_with_index.all? do |value, index|

                  debug_me{[
                    :value,
                    :index,
                    "fact_array[index]"
                  ]} if debug

                  value.nil?      || 
                  [nil] == value  ||
                  value == fact_array[index]
                end
              end

    result
  end
end
