# table_read/country_language_map.rb

require 'pathname'
require 'json'

unless defined? CountryLanguageMap
  CountryLanguageMap = JSON.parse (Pathname.new(__FILE__).parent + 'country_locale_map.json').read
end
