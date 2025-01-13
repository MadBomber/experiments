module AIChat
  class Client
    include Raix::ChatCompletion
    include Raix::FunctionDispatch

    # Tools
    include Tools::Weather
    include Tools::Web

    attr_reader :user_interaction

    def initialize(user_interaction: nil)
      @user_interaction = user_interaction
      super()
    end
  end
end 