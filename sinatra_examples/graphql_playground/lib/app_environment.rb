# lib/environment.rb

# Handle all the required and optional system environment variables
module AppEnvironment

  class MissingSystemEnvironmentVariable < RuntimeError; end

  { # Hse nil as default when SEV is required

    app_bind:     'tcp://0.0.0.0',
    app_env:      'development',
    app_port:     4567,
    dbadapter:    'postgresql',
    dbhost:       'localhost',
    dbport:       5432,
    dbname:       'graphql',
    dbpass:       'postgres',
    dbuser:       'postgres',

  }.each_pair do |key, default|
    sev   = key.to_s.upcase
    value = ENV.fetch(sev) {default}
    raise MissingSystemEnvironmentVariable, "#{sev} is undefined without a default" if value.nil?

    Kernel.const_set(sev, value)
  end


  def development?
    'development' == APP_ENV
  end

  def test?
    'test' == APP_ENV
  end

  def production?
    'development' == APP_ENV
  end
end
