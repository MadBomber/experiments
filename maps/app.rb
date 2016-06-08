#!/usr/bin/env ruby
#########################################################
###
##  File: app.rb
##  Desc: Playing with maps 
#

require 'pathname'
require 'leaflet_helper'

ROOT = Pathname.new(__FILE__).realpath.parent

class MissingSystemEnvironmentVariable < RuntimeError; end

unless defined?(APP_BIND)
  raise APP_BIND, "APP_BIND is undefined" if ENV['APP_BIND'].nil?
  APP_BIND = ENV['APP_BIND']
end

unless defined?(APP_PORT)
  raise MissingSystemEnvironmentVariable, "APP_PORT is undefined" if ENV['APP_PORT'].nil?
  APP_PORT = ENV['APP_PORT']
end

require 'require_all'

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'json'


require_all 'lib/**/*.rb'

require 'sinatra/base'
require 'sinatra/activerecord'

require 'sinatra/contrib/all'

require 'sinatra/param'
require 'sinatra/partial'


require_all 'db/models'

module TestData

  AREA51_LOCATION   = [37.242, -115.8191]         # Lat, Long
  DELTA             = [15, 15]  # NOTE: expresed as integer of real delta +/- 1.5 in lat, long
                                #       in order to use rand() method



  CODE_WORDS    = [
    "Magic Carpet",
    "Desert Storm",
    "Bayonet Lightning",
    "Valiant Guardian",
    "Urgent Fury",
    "Eagle Claw",
    "Crescent Wind",
    "Spartan Scorpion",
    "Overlord",
    "Rolling Thunder"
  ]

  class << self

    def get_random_codeword
      CODE_WORDS.sample
    end


    def get_random_location( fixed_point=AREA51_LOCATION, delta=DELTA )
      offset  = []
      dir     = rand(2) == 0 ? -1.0 : 1.0
      offset << dir * rand(delta.first).to_f  / 10.0
      dir     = rand(2) == 0 ? -1.0 : 1.0
      offset << dir * rand(delta.last).to_f / 10.0
      point   = fixed_point.each_with_index.map {|v, x| v + offset[x]}

      return { 'lat' => point.first, 'lon' => point.last } 

    end # def get_random_location( fixed_point=AREA51_LOCATION, delta=DELTA )
  end # class < self

end # module TestData


module APP

  class DemoError < RuntimeError; end

  class App < Sinatra::Base
    register Sinatra::ActiveRecordExtension
    register Sinatra::Contrib
    register Sinatra::Partial

    set :bind,            APP_BIND
    set :port,            APP_PORT
    set :server,          :thin  # or :puma

    set :haml,            :format => :html5
    set :views,           settings.root + '/views'
    set :public_folder,   settings.root + '/public'

    set :partial_template_engine, :haml


    helpers Sinatra::Param

  
    configure do
      mime_type :html, 'text/html'
    end


    before do
      content_type :html
    end


    # A marketting landing page
    get '/' do
      haml :index
    end

    # Return array of markers for a given map id
    # every time the map changes, generate a new set of markers around Area 51
    get '/:map_id/markers' do |map_id|
      content_type :json
      markers = [
        {
          "name":"Area 51",
          "lon":"-115.811111",
          "lat":"37.235",
          "details":"This is a good place to buy used flying saucers."
        }
      ]

      (rand(10)+1).times do |x|
        crash = {"name": "Crash ##{x+1}",
          "details": "Crash associated with project #{TestData.get_random_codeword}"
        }.merge(TestData.get_random_location)
        markers << crash
      end

      markers.to_json
    end

############################################################

  end # class App < Sinatra::Base
end # module APP


# APP::App.run!

