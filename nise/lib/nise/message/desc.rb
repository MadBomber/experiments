# message/desc.rb

class NISE::Message
  attr_accessor :description
  def desc(description_string)
    debug_me{[ :description_string ]}
    @description = description_string
  end
end # class NISE::Message
