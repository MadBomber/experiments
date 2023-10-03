#!/usr/bin/env ruby
# experiments/stocks/rover_monkey_test.rb

require 'debug_me'
include DebugMe

require 'pathname'

require 'rover-df'

########################################################
## Possible Patches to rover-df

# Add new instance methods for normalizing keys

class Rover::DataFrame
  def initialize(*args)
    super

    normalize_keys
    create_accessor_methods
  end

  private

  def normalize_keys
  	mapping = {} # old_key: new_key

  	return mapping if keys.empty?

  	keys.each do |key|
      next if is_date?(key)
  	  mapping[key] = underscore_key(sanitize_key(key))
  	end

  	rename(mapping)
  end


  def underscore_key(key)
    key.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase.to_sym
  end

  def sanitize_key(key)
    key.tr('.():/','').gsub(/^\d+.?\s/, "").tr(' ','_')
  end

  def is_date?(key)
    !/(\d{4}-\d{2}-\d{2})/.match(key.to_s).nil?
  end


  # NOTE: each key must be a Symbol
  def create_accessor_methods
  	return if keys.empty?

  	df.keys.each do |key|
  	  define_singleton_method(key) do
    	  [key]
    	end
    end
  end
end

########################################################
aapl_csv = Pathname.pwd + 'aapl.csv'

aapl_df = Rover.read_csv aapl_csv

# mapping = NormalizeKeys.call(aapl_df.keys)

# aapl_df.rename(mapping)

debug_me{[
  "aapl_df.keys",
  "aapl_df[:adj_close]"
]}

# create_accessor_methods(aapl_df)

debug_me{[ "aapl_df.adj_close" ]}


__END__

# An example of a Historical Stock price CSV file download from Yahoo Finance:

Date,Open,High,Low,Close,Adj Close,Volume
2019-01-02,38.722500,39.712502,38.557499,39.480000,37.994484,148158800
2019-01-03,35.994999,36.430000,35.500000,35.547501,34.209953,365248800
2019-01-04,36.132500,37.137501,35.950001,37.064999,35.670361,234428400
2019-01-07,37.174999,37.207500,36.474998,36.982498,35.590965,219111200
