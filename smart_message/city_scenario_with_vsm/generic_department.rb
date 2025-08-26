#!/usr/bin/env ruby
# generic_department.rb - VSM-based configurable city department template
#
# This template program uses YAML configuration to become any type of city department.
# When copied by city_council.rb, it reads its matching .yml config file for behavior.


require 'yaml'
require 'fileutils'

require_relative 'smart_message/lib/smart_message'
require_relative 'vsm/lib/vsm'


require_relative 'common/logger'
require_relative 'common/status_line'

require_relative 'generic_department/base'
require_relative 'generic_department/governance'
require_relative 'generic_department/identity'
require_relative 'generic_department/intelligence'
require_relative 'generic_department/operations'

module GenericDepartment

end

# Start the generic template service
if __FILE__ == $0
  GenericDepartment::Base.new
end
