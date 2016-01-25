

https://medium.com/iron-io-blog/how-to-create-a-tiny-docker-image-for-your-ruby-app-f8d7d622d80b


Travis Reeder


How to Create a Tiny Docker Image for your Ruby App

I’ve been on a quest to create the smallest possible Docker images for all the things, and here’s how to create a very small image for your Ruby apps (much smaller than I would have thought possible for Ruby). This post will walk you through packaging up a simple Sinatra app into a Docker image that weighs in around 18MB.

All you need for this tutorial is Docker, you don’t even need Ruby installed.

brew install docker


0) The App
Let’s start with code for a simple Hello World app, copy and paste this into a file named app.rb:

```ruby
require 'sinatra'
require "sinatra/json"

port = ENV['PORT'] || 8080
puts "STARTING SINATRA on port #{port}"
set :port, port
set :bind, '0.0.0.0'

get '/' do
  json({"Hello" => "World!"})
end
```



That is a Sinatra app that will return a jsonified Hello World response. We need a Gemfile to define our dependencies too:


```ruby
source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib'
```


1) Vendor Dependencies
Vendor your dependencies to a local directory so we can package them up easily and build any native dependencies on the right system (ie: the Docker image we’re using).

```shell
docker run --rm -it -v $PWD:/app -w /app iron/ruby-bundle bundle update
docker run --rm -it -v $PWD:/app -w /app iron/ruby-bundle bundle install --standalone --clean
```



The iron/ruby-bundle image we’re using here is a special image that has all the libs we need to build native extensions.

2) Test the App
Let’s test the app before we bundle it up:

```shell
docker run -it --rm -v $PWD:/app -w /app -p 8080:8080 iron/ruby ruby app.rb
```



Check http://localhost:8080/ to ensure it’s running correctly. Notice we’re using iron/ruby here, this is a much smaller image than iron/ruby-bundle and has everything we need to run the app. Both of these iron/ruby* images are based on the very small Alpine Linux image (which is totally awesome).

3) Build Docker Image
Copy and paste the following into a file named Dockerfile:

```text
FROM iron/ruby
WORKDIR /app
ADD . /app
ENTRYPOINT ["ruby", "app.rb"]
```


```shell
docker build -t treeder/hello-sinatra:latest .
```


Now build the image:


4) Test the Docker Image
Now that it’s built, let’s test the image:

```shell
docker run -it --rm -v $PWD:/app -w /app -p 8080:8080 iron/ruby ruby app.rb
```


Once again, check http://localhost:8080/ to ensure it’s running correctly.

Conclusion
That’s all she wrote. You now have a clean, tiny Docker image containing your Ruby app.

You can find the full source code for this example here: https://github.com/treeder/hello-sinatra

One last thing, if you want to distribute your app, just push it up to Docker Hub:

```shell
docker push treeder/hello-sinatra
```


Then anyone can run your app just by running the same docker run command as above.


