# examples/start_simulation.rb

class StartSimulation < NISE::Message

  desc "start a simulation"
  field :sim_name, :string

end # class StartSimulation < NISE::Message