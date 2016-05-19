################################################
###
##  File: handle_503_in_mechanize.rb
##  Desc: an exponontial backoff stragety for handling 503 - server not available errors
#

require 'exponential_backoff'
require 'mechanize'

module MechanizeBackoff
  def get(*args)
    response = super

    backoff.clear

    return response
  rescue Mechanize::ResponseCodeError => exception
    unless exception.response_code == '503'
      raise exception
    end

    sleep(backoff.next_interval)

    retry
  end

  def backoff
    @backoff ||= ExponentialBackoff.new(2.0, 60.0)
  end
end

class Mechanize
  prepend MechanizeBackoff
end

