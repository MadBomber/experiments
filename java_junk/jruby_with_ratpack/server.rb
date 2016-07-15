# server.rb
# Reference: https://blog.heroku.com/reactive_ruby_building_real_time_apps_with_jruby_and_ratpack



require 'java' 
require 'jruby/core_ext'
require 'bundler/setup' 
Bundler.require

java_import 'ratpack.server.RatpackServer'

java_import 'ratpack.stream.Streams'
java_import 'ratpack.http.ResponseChunks'
java_import 'java.time.Duration'


RatpackServer.start do |b| 
  b.handlers do |chain| 
    chain.get do |ctx| 
      ctx.render("Hello from Ratpack+JRuby") 
    end

    chain.get("stream") do |ctx|
      publisher = Streams.periodically(ctx, Duration.ofMillis(1000)) do |i|
        i < 10 ? i.to_s : nil
      end
      ctx.render(ResponseChunks.stringChunks(publisher))
    end

  end
end
