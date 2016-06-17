#!/usr/bin/env ruby
#########################################################
###
##  File: app.rb
##  Desc: Playing with maps 
#

require 'pathname'
require 'leaflet_helper'

$markers = Hash.new(LeafletHelper::ManageMarkers.new)

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

  CAUSE = [
    "overload on the flux stream capacitor",
    "pilot error",
    "programming error in the navigation system",
    "unknown",
    "bird strike",
    "union organizers",
    "pilot FWI - flying while intoxicated",
    "pilot - inability to follow instructions given in any Earth language",
    "flew too near the sun"
  ]

  class << self

    def get_random_codeword
      CODE_WORDS.sample
    end


    def get_random_cause
      CAUSE.sample
    end


    def get_random_location( fixed_point=AREA51_LOCATION, delta=DELTA )
      offset  = []
      dir     = rand(2) == 0 ? -1.0 : 1.0
      offset << dir * rand(delta.first).to_f  / 10.0
      dir     = rand(2) == 0 ? -1.0 : 1.0
      offset << dir * rand(delta.last).to_f / 10.0
      point   = fixed_point.each_with_index.map {|v, x| v + offset[x]}

      return { lat: point.first, lon: point.last } 

    end # def get_random_location( fixed_point=AREA51_LOCATION, delta=DELTA )
  end # class < self

end # module TestData


# setup some static markers

%w[ map map2 ].each do |map_id|

  $markers[map_id].clear

  $markers[map_id].add id: 'Secret Place',
    lat: 37.235, lon: -115.811111,
    html: <<~EOS
      <h2>Area 51 on #{map_id}</h2>
      <p>This is a good place to buy used flying saucers.</p>
    EOS

  template = <<~EOS
    <h1>{classification}</h1>
    <h3>Crash Site \#{x}</h3>
    <em>Location: [{lat}, {lon}]</em>
    <p>Project {codeword}</p>
    <p>Cause of crash: {cause}</p>
  EOS

  30.times do |x|
    location  = TestData.get_random_location

    data = {
      x:        x,
      lat:      location[:lat],
      lon:      location[:lon],
      codeword: TestData.get_random_codeword,
      cause:    TestData.get_random_cause
    }

    $markers[map_id].add id: "Crash Site",
      lat:  location[:lat],
      lon:  location[:lon],
      html: template,
      data: data
  end

end # %w[ map map2 ].each do |map_id|




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
    # This route is coupled with the route that is used with: LeafletHelper::L.add_support_for_markers
    get '/:map_id/markers' do |map_id|
      content_type :json

      $markers[:map_id].replace_with('Crash Site', {classification: 'Unclassified'})

      $markers[map_id].to_json
    end

############################################################

  end # class App < Sinatra::Base
end # module APP


# APP::App.run!

