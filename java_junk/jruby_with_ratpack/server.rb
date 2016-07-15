# server.rb

require 'java' 
require 'jruby/core_ext'
require 'bundler/setup' 
Bundler.require

java_import 'ratpack.server.RatpackServer'

RatpackServer.start do |b| 
  b.handlers do |chain| 
    chain.get do |ctx| 
      ctx.render("Hello from Ratpack+JRuby") 
    end
  end
end
