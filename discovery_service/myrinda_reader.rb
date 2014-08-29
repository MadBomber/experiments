require 'myrinda'

  ts = tuplespace
  blogs = ts.take([:blog, nil, nil])
  blogs.each do |b|
    puts "#{b[1]: #{b[2]}"
  end
