#!/usr/bin/env ruby
######################################################
###
##  File: hipchat_gateway_client.rb
##  Desc: Client for distributed Ruby (dRuby) gateway to hipchat
##        Required for hipchat integration with Rails v4.2.3
##        due to an openSSL error within Rails.
#

require 'drb/drb'

DRb.start_service
gateway = DRbObject.new_with_uri('druby://localhost:9999')

gateway.notify({
  fromuser: 'dewayne',
  message:  'Another test; this time using dRuby',
  notify:   false,
  color:    'green'
})
