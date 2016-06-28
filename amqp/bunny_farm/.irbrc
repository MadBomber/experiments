require 'debug_me'
include DebugMe

require 'awesome_print'
require 'require_all'

require 'bunny_farm'

require_all 'messages/*.rb'

BunnyFarm.config do
 config_dir   File.dirname(__FILE__)+'/config'
 bunny_file   'rabbitmq.yml.erb'
end

ap BunnyFarm::CONFIG
