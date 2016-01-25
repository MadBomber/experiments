require 'sinatra'  
require 'redis'

get '/' do  
  redis = Redis.new(:url => ENV['REDIS_URL'])
  redis.incr "count"
  "Hello, world called #{redis.get("count")} times"
end  
