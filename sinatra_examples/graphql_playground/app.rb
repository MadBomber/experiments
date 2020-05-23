#!/usr/bin/env ruby
#########################################################
###
##  File: app.rb
##  Desc: play with some graphql ideas
#

puts <<~HEADER

  ============
  == app.rb ==
  ============

HEADER


require 'pathname'

ROOT = Pathname.new(__FILE__).realpath.parent

require 'require_all'

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'json'


require_all 'lib/**/*.rb'

include AppEnvironment


require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/activerecord'

require 'sinatra/contrib/all'

require 'sinatra/param'
require 'sinatra/partial'

require 'sinatra/reloader' if development?

require 'rack/contrib'

require_all 'db/models'


module APP

  class DemoError < RuntimeError; end

  class App < Sinatra::Base
    register Sinatra::ActiveRecordExtension
    register Sinatra::Contrib
    register Sinatra::Partial

    use Rack::PostBodyContentTypeParser

    set :database_file,   'config/database.yml'

    set :bind,            APP_BIND
    set :port,            APP_PORT
    set :server,          :puma

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

    get '/hello.json' do
      message = { success: true, message: 'hello'}
      json message
    end

    get '/speakers' do
      @speakers = Speaker.all
      json @speakers
    end

    post '/graphql' do
      result = AppSchema.execute(
        params[:query],
        variables: params[:variables],
        context: { current_user: nil },
      )
      json result
    end

############################################################

  end # class App < Sinatra::Base
end # module APP


# APP::App.run!

