# doge_vsm/coordination.rb

module DogeVSM
  class Coordination < VSM::Coordination
    def handle(message, bus:, **opts)
      # Add workflow orchestration if needed
      super
    end
  end
end