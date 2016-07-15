# Ratpack JRuby Example

An example of how to use the [Ratpack web framework](https://ratpack.io/) from [JRuby](http://jruby.org/).

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Local Setup

```
$ git clone https://github.com/jkutner/ratpack-jruby-example
$ cd ratpack-jruby-example
$ jgem install jbundler bundler
$ jbundle install
$ bundle install --binstubs
$ export DATABASE_URL="postgres://localhost:5432/ratpack"
$ bin/rake db:migrate
$ jruby server.rb
```

## Heroku Setup

```
$ heroku create --addons heroku-postgresql
$ git push heroku master
$ heroku run rake db:migrate
```

## License

Apache v2