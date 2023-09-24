#!/usr/bin/env ruby

require 'amazing_print'
require 'debug_me'
include DebugMe

debug_me

require 'sqa'

debug_me

require 'sqa/cli'

debug_me


ap SQA.init "-c ~/.sqa.yml -d -v"
