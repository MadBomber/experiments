#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/test_helper.rb
##  Desc: Shared minitest bootstrap for prose_score
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'prose_score'
