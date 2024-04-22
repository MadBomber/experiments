# experiments/using_methods_as_data/rules.rb

module Rules
  class << self
    def method_without_params
      # Method body
      nil
    end

    def method_with_one_param(param1:)
      # Method body
      nil
    end

    def method_with_multiple_params(param1:, param2:)
      # Method body
      nil
    end

    def method_with_optional_2nd_parameter(param1:, param2: 25)
      25 == param2
    end

    def teenagers?(age) = age < 18
    def adults?(age)    = age >= 18
  end
end
