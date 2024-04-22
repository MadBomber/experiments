#!/usr/bin/env ruby

module SQA; end

class SQA::DataFrame2

  def initialize(df)
    @df 	= df
    @type = df.class.name.split(':').first.downcase.to_sym

    self.class.include_adapter_for(@type)
  end


  def method_missing(method, *args, &block)
    @df.send(method, *args, &block)
  end


  def self.method_missing(method, *args, &block)
    @df.class.send(method, *args, &block)
  end

  #######################################################
  ## Class Methods

  def self.include_adapter_for(data_frame_type)
    case data_frame_type
    when :rover
      include SQA::DataFrame::RoverAdapter
    when :polars
      include SQA::DataFrame::PolarsAdapter
    else
      raise "Invalid data frame type: #{data_frame_type}"
    end
  end
end


module SQA
	class DataFrame
		module RoverAdapter
			def load(path_to_file)
				@df = Rover.read_csv(path_to_file)
			end

			def append(new_df)
				@df.concat(new_df)
			end
		end
	end
end


module SQA
	class DataFrame
		module PolarsAdapter
			def load(path_to_file)
				@df = Polars.xyzzy(path_to_file)
			end

			def append(new_df)
				@df.xyzzy(new_df)
			end
		end
	end
end

__END__

require 'minitest/autorun'

class TestDataFrame < Minitest::Test
  def test_include_adapter_for_rover
    df = SQA::DataFrame.new(Rover.new)
    assert_includes df.class.included_modules, SQA::DataFrame::RoverAdapter
  end

  def test_include_adapter_for_polars
    df = SQA::DataFrame.new(Polars.new)
    assert_includes df.class.included_modules, SQA::DataFrame::PolarsAdapter
  end

  def test_include_adapter_for_invalid_type
    df = SQA::DataFrame.new(Object.new)
    assert_raises(RuntimeError) do
      df.include_adapter_for(:invalid)
    end
  end

  # def test_method_missing
  #   df = SQA::DataFrame.new(Object.new)
  #   df.load("path/to/file")
  #   assert_equal "path/to/file", df.instance_variable_get(:@df)
  # end

  # def test_method_missing_class
  #   SQA::DataFrame.load("path/to/file")
  #   assert_equal "path/to/file", SQA::DataFrame.instance_variable_get(:@df)
  # end
end


