#!/user/bin/env ruby
# Simple Authentication
# simple_authentication.rb
# Source: http://www.rubypigeon.com/posts/how-to-implement-simple-authentication-without-devise/?utm_source=rubyweekly&utm_medium=email
# src: https://gist.github.com/tomdalling/b873e731e5c6c56431807d40a904f6cf
#

require 'bundler/inline'
gemfile(true) do
  source 'https://rubygems.org'
  gem 'sinatra', '~> 1.4'
  gem 'bcrypt', '~> 3.1'
end

require 'sinatra/base'
require 'bcrypt'

def hash_password(password)
  BCrypt::Password.create(password).to_s
end

def test_password(password, hash)
  BCrypt::Password.new(hash) == password
end

User = Struct.new(:id, :username, :password_hash)
USERS = [
  User.new(1, 'bob', hash_password('the builder')),
  User.new(2, 'sally', hash_password('go round the sun')),
]

class AuthExample < Sinatra::Base
  enable :inline_templates
  enable :sessions

  get '/' do
    if current_user
      erb :home
    else
      redirect '/sign_in'
    end
  end

  get '/sign_in' do
    erb :sign_in
  end

  post '/sign_in' do
    user = USERS.find { |u| u.username == params[:username] }
    if user && test_password(params[:password], user.password_hash)
      session.clear
      session[:user_id] = user.id
      redirect '/'
    else
      @error = 'Username or password was incorrect'
      erb :sign_in
    end
  end

  post '/create_user' do
    USERS << User.new(
      USERS.size + 1, #id
      params[:username], #username
      hash_password(params[:password]) #password_hash
    )

    redirect '/'
  end

  post '/sign_out' do
    session.clear
    redirect '/sign_in'
  end

  helpers do
    def current_user
      if session[:user_id]
         USERS.find { |u| u.id == session[:user_id] }
      else
        nil
      end
    end
  end

  run!
end

__END__

@@ sign_in
  <h1>Sign in</h1>
  <% if @error %>
    <p class="error"><%= @error %></p>
  <% end %>
  <form action="/sign_in" method="POST">
    <input name="username" placeholder="Username" />
    <input name="password" type="password" placeholder="Password" />
    <input type="submit" value="Sign In" />
  </form>

@@ home
  <h1>Home</h1>
  <p>Hello, <%= current_user.username %>.</p>
  <form action="/sign_out" method="POST">
    <input type="submit" value="Sign Out" />
  </form>

  <p>There are <%= USERS.size %> users registered:</p>
  <ul>
    <% USERS.each do |user| %>
      <li><%= user.username %></li>
    <% end %>
  </ul>

  <h2>Create New User</h2>
  <form action="/create_user" method="POST">
    <input name="username" placeholder="Username" />
    <input name="password" placeholder="Password" />
    <input type="submit" value="Create User" />
  </form>

@@ layout
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8" />
      <title>Simple Authentication Example</title>
      <style>
        input { display: block; }
        .error { color: red; }
      </style>
    </head>
    <body><%= yield %></body>
  </html>
