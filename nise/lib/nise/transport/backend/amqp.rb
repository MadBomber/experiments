# transport/backend/amqp.rb

# TODO: revisit the 'bunny_farm' gem

require 'bunny'

module Transport::Backend
  class AMQP
    DEFAULT = {
      host: 'localhost'
    }
    def initialize(options={})
      @config = DEFAULT.merge(options)
    end
  end # AMQP
end # module Transport::Backend
