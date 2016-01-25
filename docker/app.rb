require_relative 'bundle/bundler/setup'
require 'sinatra'
require "sinatra/json"

port = ENV['PORT'] || 8080
puts "STARTING SINATRA on port #{port}"
set :port, port
set :bind, '0.0.0.0'

get '/' do
  json({"Hello" => "World!"})
end
