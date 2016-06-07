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



############################################################

  end # class App < Sinatra::Base
end # module APP


# APP::App.run!

