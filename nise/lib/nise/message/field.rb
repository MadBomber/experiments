# message/field.rb

class NISE::Message
  class DuplicateFieldName < RuntimeError; end

  # TODO: flesh out this class as field becomes more complex
  Field = Struct.new(
    :name,  # The field name
    :type,  # The type of a field e.g. its class
    :order  # The order of definition - used in binary payloads
  ) do
    def initialize(*)
      super
      self.order ||= 0
    end
  end

  attr_accessor :fields


  def field(field_name, field_type)
    @fields = Hash.new unless @fields.is_a? Hash
    debug_me{[ :field_name, :field_type]}
    insert_field Field.new(field_name, field_type)
    debug_me{:fields}
  end


  def insert_field(a_field)
    validate_field_definition(a_field)
    a_field.order = @fields.size+1
    @fields[a_field.name] = a_field.to_h
  end


  def validate_field_definition(a_field)
    raise DuplicateFieldName if @fields.has_key? a_field.name
  end
end # class NISE::Message
