# experiments/prolog/fact.rb

class Fact
  attr_accessor :head, :predicate, :objects

  # Initializes a new Fact instance
  def initialize(head, predicate, *objects)
    @head       = head
    @predicate  = predicate
    @objects    = objects
  end


  def method_missing(method_name, *args, &block)
    method_name_string = method_name.to_s
    predicate_query = @predicate.to_s + "?"

    if method_name_string == predicate_query
      if args.empty?
        return true
      elsif args.size >= 1 && @objects.include?(args)
        return true
      end

      return false
    end

    super
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.end_with?('?') || super
  end

  # A simple string representation for demonstration.
  def to_s
    "#{head} #{predicate} #{objects.join(', ')}"
  end


  def to_a
    [head, predicate, objects]    
  end


  def inverse(inverse_predicate = nil)
    # Array to hold the original fact and the new inverted facts
    inverted_facts = [self]

    # If inverse_predicate is nil, use the original predicate for inversion
    predicate_for_inversion = inverse_predicate || @predicate
    @objects.each do |object|
      # For each object, create a new Fact with the roles of head and object inverted
      inverted_facts << Fact.new(object, predicate_for_inversion, @head)
    end

    inverted_facts
  end


  #########################################################
  ## Class methods

  # All class methods will be defined in the eigenclass specified below
  class << self
    # Enhanced method_missing at the class level
    def method_missing(method_name, *args, &block)
      method_str = method_name.to_s
      if method_str.end_with?('!')
        predicate = method_str.chop # Remove the '!' from the end
        fact = new(args[0], predicate, args[1..-1])
      else
        fact = new(args[0], method_name, args[1..-1])
      end
      fact
    end

    # Ensure we correctly respond to methods that are missing
    def respond_to_missing?(method_name, include_private = false)
      true
    end
  end
end
