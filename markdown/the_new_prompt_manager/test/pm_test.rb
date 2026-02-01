# frozen_string_literal: true

require_relative 'test_helper'

class PMParseTest < Minitest::Test
  def test_parse_extracts_metadata_and_content
    input = "---\ntitle: Hello\n---\nSome content\n"
    parsed = PM.parse(input)

    assert_equal 'Hello', parsed.metadata.title
    assert_equal "Some content\n", parsed.content
  end

  def test_parse_with_no_metadata
    parsed = PM.parse("Just plain text")

    assert_nil parsed.metadata.title
    assert_equal "Just plain text", parsed.content
  end

  def test_parse_with_multiple_metadata_fields
    input = "---\ntitle: Test\nmodel: gpt-4\ntemperature: 0.5\n---\nContent\n"
    parsed = PM.parse(input)

    assert_equal 'Test', parsed.metadata.title
    assert_equal 'gpt-4', parsed.metadata.model
    assert_equal 0.5, parsed.metadata.temperature
  end

  def test_parse_with_leading_whitespace
    input = "\n\n---\ntitle: Hello\n---\nContent\n"
    parsed = PM.parse(input)

    assert_equal 'Hello', parsed.metadata.title
  end

  def test_bracket_accessor_delegates_to_metadata
    parsed = PM.parse("---\ntitle: Test\n---\nContent\n")

    assert_equal 'Test', parsed['title']
  end

  def test_metadata_defaults_shell_to_true
    parsed = PM.parse("---\ntitle: Test\n---\nContent\n")

    assert_equal true, parsed.metadata.shell
  end

  def test_metadata_defaults_erb_to_true
    parsed = PM.parse("---\ntitle: Test\n---\nContent\n")

    assert_equal true, parsed.metadata.erb
  end
end

class PMMetadataTest < Minitest::Test
  def test_dot_notation_access
    parsed = PM.parse_file(fixture('simple.md'))

    assert_equal 'Simple Prompt', parsed.metadata.title
    assert_equal 'openai', parsed.metadata.provider
    assert_equal 'gpt-4', parsed.metadata.model
  end

  def test_predicate_methods_for_boolean_true
    parsed = PM.parse_file(fixture('simple.md'))

    assert_equal true, parsed.metadata.shell?
    assert_equal true, parsed.metadata.erb?
  end

  def test_predicate_methods_for_boolean_false
    parsed = PM.parse_file(fixture('shell_disabled.md'))

    assert_equal false, parsed.metadata.shell?
  end

  def test_predicate_methods_for_erb_false
    parsed = PM.parse_file(fixture('erb_disabled.md'))

    assert_equal false, parsed.metadata.erb?
  end

  def test_non_boolean_keys_have_no_predicate
    parsed = PM.parse_file(fixture('simple.md'))

    refute_respond_to parsed.metadata, :title?
  end

  def test_date_values_parsed_as_date_objects
    parsed = PM.parse_file(fixture('with_dates.md'))

    assert_instance_of Date, parsed.metadata.created
    assert_equal Date.new(2026, 2, 1), parsed.metadata.created
  end

  def test_time_values_parsed_as_time_objects
    parsed = PM.parse_file(fixture('with_dates.md'))

    assert_instance_of Time, parsed.metadata.updated
  end

  def test_parameters_accessible_via_dot_notation
    parsed = PM.parse_file(fixture('with_parameters.md'))

    assert_equal 'ruby', parsed.metadata.parameters['language']
    assert_nil parsed.metadata.parameters['code']
    assert_equal 'concise', parsed.metadata.parameters['style']
  end
end

class PMParseFileTest < Minitest::Test
  def test_parse_file_extracts_metadata
    parsed = PM.parse_file(fixture('simple.md'))

    assert_equal 'Simple Prompt', parsed.metadata.title
    assert_equal 'openai', parsed.metadata.provider
    assert_equal 'gpt-4', parsed.metadata.model
  end

  def test_parse_file_extracts_content
    parsed = PM.parse_file(fixture('simple.md'))

    assert_includes parsed.content, 'simple prompt with no parameters'
  end

  def test_parse_file_adds_directory_to_metadata
    parsed = PM.parse_file(fixture('simple.md'))

    assert_equal FIXTURES, parsed.metadata.directory
  end

  def test_parse_file_adds_name_to_metadata
    parsed = PM.parse_file(fixture('simple.md'))

    assert_equal 'simple.md', parsed.metadata.name
  end

  def test_parse_file_adds_created_at_to_metadata
    parsed = PM.parse_file(fixture('simple.md'))

    assert_instance_of Time, parsed.metadata.created_at
  end

  def test_parse_file_adds_modified_at_to_metadata
    parsed = PM.parse_file(fixture('simple.md'))

    assert_instance_of Time, parsed.metadata.modified_at
  end

  def test_parse_file_with_no_metadata
    parsed = PM.parse_file(fixture('no_metadata.md'))

    assert_equal FIXTURES, parsed.metadata.directory
    assert_equal 'no_metadata.md', parsed.metadata.name
    assert_includes parsed.content, 'Just plain content'
  end
end

class PMExpandShellTest < Minitest::Test
  def test_expand_env_var_bare
    ENV['PM_TEST_VAR'] = 'hello'
    result = PM.expand_shell('Value: $PM_TEST_VAR')

    assert_equal 'Value: hello', result
  ensure
    ENV.delete('PM_TEST_VAR')
  end

  def test_expand_env_var_braced
    ENV['PM_TEST_VAR'] = 'world'
    result = PM.expand_shell('Value: ${PM_TEST_VAR}')

    assert_equal 'Value: world', result
  ensure
    ENV.delete('PM_TEST_VAR')
  end

  def test_missing_env_var_replaced_with_empty_string
    ENV.delete('PM_NONEXISTENT_VAR')
    result = PM.expand_shell('Value: $PM_NONEXISTENT_VAR end')

    assert_equal 'Value:  end', result
  end

  def test_expand_command_substitution
    result = PM.expand_shell('Result: $(echo hello)')

    assert_equal 'Result: hello', result
  end

  def test_expand_nested_command
    result = PM.expand_shell('Result: $(echo $(echo nested))')

    assert_equal 'Result: nested', result
  end

  def test_expand_multiple_commands
    result = PM.expand_shell('A: $(echo one) B: $(echo two)')

    assert_equal 'A: one B: two', result
  end

  def test_failed_command_raises
    assert_raises(RuntimeError) do
      PM.expand_shell('$(exit 1)')
    end
  end

  def test_expand_shell_in_parse_file
    ENV['PM_TEST_USER'] = 'alice'
    ENV['PM_TEST_HOME'] = '/home/alice'
    parsed = PM.parse_file(fixture('with_shell.md'))

    assert_includes parsed.content, 'User: alice'
    assert_includes parsed.content, 'Home: /home/alice'
    assert_includes parsed.content, 'Echo: hello'
  ensure
    ENV.delete('PM_TEST_USER')
    ENV.delete('PM_TEST_HOME')
  end

  def test_does_not_expand_lowercase_vars
    result = PM.expand_shell('Value: $lowercase')

    assert_equal 'Value: $lowercase', result
  end
end

class PMToSTest < Minitest::Test
  def test_to_s_with_no_parameters_no_erb
    parsed = PM.parse_file(fixture('simple.md'))
    result = parsed.to_s

    assert_includes result, 'simple prompt with no parameters'
  end

  def test_to_s_with_erb_and_no_parameters
    parsed = PM.parse_file(fixture('with_erb.md'))
    result = parsed.to_s

    assert_includes result, Time.now.strftime('%A')
    assert_includes result, '4'
  end

  def test_to_s_with_all_defaults
    parsed = PM.parse_file(fixture('all_defaults.md'))
    result = parsed.to_s

    assert_includes result, 'hello, world!'
  end

  def test_to_s_overrides_defaults
    parsed = PM.parse_file(fixture('all_defaults.md'))
    result = parsed.to_s('greeting' => 'hi', 'name' => 'bob')

    assert_includes result, 'hi, bob!'
  end

  def test_to_s_with_symbol_keys
    parsed = PM.parse_file(fixture('all_defaults.md'))
    result = parsed.to_s(greeting: 'hey', name: 'sue')

    assert_includes result, 'hey, sue!'
  end

  def test_to_s_with_required_parameter_provided
    parsed = PM.parse_file(fixture('with_parameters.md'))
    result = parsed.to_s('code' => 'puts "hi"')

    assert_includes result, 'ruby'
    assert_includes result, 'concise'
    assert_includes result, 'puts "hi"'
  end

  def test_to_s_raises_on_missing_required_parameter
    parsed = PM.parse_file(fixture('with_parameters.md'))

    error = assert_raises(ArgumentError) { parsed.to_s }
    assert_includes error.message, 'code'
  end

  def test_to_s_with_no_metadata
    parsed = PM.parse_file(fixture('no_metadata.md'))
    result = parsed.to_s

    assert_includes result, 'Just plain content'
  end
end

class PMShellFlagTest < Minitest::Test
  def test_shell_disabled_skips_env_expansion
    parsed = PM.parse_file(fixture('shell_disabled.md'))

    assert_includes parsed.content, '$USER'
  end

  def test_shell_disabled_skips_command_substitution
    parsed = PM.parse_file(fixture('shell_disabled.md'))

    assert_includes parsed.content, '$(echo hello)'
  end

  def test_shell_enabled_by_default
    ENV['PM_TEST_USER'] = 'alice'
    ENV['PM_TEST_HOME'] = '/home/alice'
    parsed = PM.parse_file(fixture('with_shell.md'))

    assert_includes parsed.content, 'User: alice'
  ensure
    ENV.delete('PM_TEST_USER')
    ENV.delete('PM_TEST_HOME')
  end

  def test_shell_flag_in_metadata
    parsed = PM.parse_file(fixture('shell_disabled.md'))

    assert_equal false, parsed.metadata.shell
    assert_equal false, parsed.metadata.shell?
  end
end

class PMErbFlagTest < Minitest::Test
  def test_erb_disabled_skips_erb_processing
    parsed = PM.parse_file(fixture('erb_disabled.md'))
    result = parsed.to_s

    assert_includes result, '<%= name %>'
  end

  def test_erb_enabled_by_default
    parsed = PM.parse_file(fixture('all_defaults.md'))
    result = parsed.to_s

    assert_includes result, 'hello, world!'
    refute_includes result, '<%='
  end

  def test_erb_disabled_ignores_parameter_values
    parsed = PM.parse_file(fixture('erb_disabled.md'))
    result = parsed.to_s('name' => 'override')

    assert_includes result, '<%= name %>'
  end

  def test_erb_flag_in_metadata
    parsed = PM.parse_file(fixture('erb_disabled.md'))

    assert_equal false, parsed.metadata.erb
    assert_equal false, parsed.metadata.erb?
  end
end

class PMBothDisabledTest < Minitest::Test
  def test_both_disabled_preserves_content
    parsed = PM.parse_file(fixture('both_disabled.md'))
    result = parsed.to_s

    assert_includes result, '$USER'
    assert_includes result, '<%= name %>'
    assert_includes result, '$(echo should not run)'
  end
end
