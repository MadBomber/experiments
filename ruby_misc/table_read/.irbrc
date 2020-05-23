
require 'debug_me'
include DebugMe

require 'awesome_print'

require 'pathname'

require_relative './spec_script'

HOME        = Pathname.new ENV['HOME']
DOC_DIR     = HOME + 'Documents'
# SCRIPT_PATH = DOC_DIR + 'my_new_screenplay.kitsp'
SCRIPT_PATH = DOC_DIR + 'EMP.kitsp'

SS = SpecScript.new SCRIPT_PATH

