# test/message/message_test.rb

require_relative '../../test_helper'
require_relative '../../../examples/messages/start_simulation'

class MessageTest < Minitest::Test
  def test_class
    assert_equal StartSimulation.superclass, NISE::Message
  end

  def test_desc
    message = StartSimulation.new
    assert_equal message.description, 'start a simulation'
  end

  def test_fields
    message = StartSimulation.new
    assert message.fields.is_a?(Hash)
    assert_equal message.fields.size, 1
    assert message.fields.has_key?(:sim_name)
    assert_equal message.fields[:sim_name][:type], :string
    assert_equal 1, message.fields[:sim_name][:order]
  end
end # class MessageTest < Minitest::Test
