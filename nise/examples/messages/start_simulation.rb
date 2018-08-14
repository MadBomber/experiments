# examples/messages/start_simulation.rb

require_relative '../../lib/nise/message'

class StartSimulation < NISE::Message
  def initialize
    desc "start a simulation"
    field :sim_name, :string
    super
  end
end # class StartSimulation < NISE::Message