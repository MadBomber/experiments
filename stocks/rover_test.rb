#!/usr/bin/env ruby

require 'amazing_print'
require 'debug_me'
include DebugMe

require 'csv'
require 'pathname'

require 'rover-df'

########################################################
## Possible Patches to rover-df

class NormalizeKeys
  def self.call(keys)
  	mapping = {} # old_key: new_key

  	return mapping if keys.empty?

  	keys.each do |key|
          next if is_date?(key)
  	  mapping[key] = underscore_key(sanitize_key(key))
  	end

  	mapping
  end

  private

  def self.underscore_key(key)
    key.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase.to_sym
  end

  def self.sanitize_key(key)
    key.tr('.():/','').gsub(/^\d+.?\s/, "").tr(' ','_')
  end

  def self.is_date?(key)
    !/(\d{4}-\d{2}-\d{2})/.match(key.to_s).nil?
  end
end

# SMELL: not needed?
# def sekf.convert_hash_keys(value)
#   case value
#   when Array
#     value.map { |v| convert_hash_keys(v) }
#   when Hash
#     Hash[value.map { |k, v| [ NormalizeKey.new(key: k).call, convert_hash_keys(v) ] }]
#   else
#     value
#   end
# end


def create_accessor_methods(df)

  df
end


########################################################
aapl_csv = Pathname.pwd + 'aapl.csv'

aapl_df = Rover.read_csv aapl_csv

debug_me{[
	"aapl_df.size",
	"aapl_df.keys",
	"aapl_df.methods"
]}


mapping = NormalizeKeys.call(aapl_df.keys)


debug_me{[ :mapping ]}

aapl_df.rename(mapping)

debug_me{[ "aapl_df.keys" ]}

debug_me{[ "aapl_df[:adj_close]" ]}

create_accessor_methods(aapl_df)

ap aapl_df.adj_close

