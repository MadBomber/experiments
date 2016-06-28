#!/usr/bin/env ruby
##############################################
###
##  File: send_some_suggestions.rb
##  Desc: Lets plant some buEverryone has an opinion
#

require 'debug_me'
include DebugMe

require 'awesome_print'

require 'bunny_farm'
require 'require_all'

require_all 'messages/*.rb'

BunnyFarm.config(File.dirname(__FILE__)+'/config/rabbitmq.yml.erb')


ap BunnyFarm::CONFIG


10.times do |x|

  form_contents = {
      author: {
          name: 'Jimmy Smith',
          mailing_address: '123 Main St. USA',
          email_address: 'little_jimmy@smith.us',
          phone_number: '+19995551212'
      },
      tv_show_name: 'Lost In Space',
      suggestion: "##{x}). Why does doctor Smith have to be such a meanie?",
      lots_of_other_house_keeping_junk: {}
  }

  tss = TvShowSuggestion.new(form_contents.to_json)
  tss.publish(:action)
  #debug_me(tag: "suggestion has been submitted", header:false){[ :x ]}
  #sleep rand(2)

end
