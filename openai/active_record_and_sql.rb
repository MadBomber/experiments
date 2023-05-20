#!/usr/bin/env ruby
# experiments/openai/active_record_and_sql.rb

require 'boxcars'

require 'debug_me'
include DebugMe

require 'active_record'
require 'nenv'

# Parse the PGDNS environment variable
uri = URI.parse Nenv.pgdns

# Set up the ActiveRecord connection
ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: uri.host,
  port: uri.port,
  database: uri.path[1..-1],
  username: uri.user,
  password: uri.password,
  # sslmode: uri.query['sslmode']
)

puts ActiveRecord::Base.connection.current_database


# get the answer using SQL
# Did not work had too many tokens error
# boxcar = Boxcars::SQL.new
# boxcar.run "How many license_keys are there?"


class LicenseKey        < ActiveRecord::Base; end
class Clinician         < ActiveRecord::Base; end
class ClinicianAddress  < ActiveRecord::Base; end
class PostalCode        < ActiveRecord::Base; end

emr = Boxcars::ActiveRecord.new(
  name: 'emr', 
  models: [LicenseKey, Clinician, ClinicianAddress, PostalCode]
)

# These are all good:
# emr.run "how many license keys do we have?"
# emr.run "how many clinicians do we have?"
# emr.run "In which state is zip code 71111?"
# emr.run "how many unique clinician_addresses are by state?"
# emr.run "rake the states by most to least based upon how many unique clinician_addresses are in the state?"
# emr.run "what are the 10 states with the most zip codes?"
# emr.run "which state has the fewest zip codes?"
# emr.run "A clinician's full name is a concatenation of their first middle and last names.  List the full names of the first 10 clinicians."
# emr.run "which clinicians do not have the last name 'MadBomber'"
# emr.run "do all clinicians have the same last name?"

# By default the ActiveRecord Boxcar is READ-ONLY

# custom change approval proc

rubber_stamp = Proc.new do |change_count, code|
    debug_me{[
      :change_count,
      :code
    ]}

    puts ">>> Approving #{change_count} changes <<<"
    true
end

rw_emr = Boxcars::ActiveRecord.new(
  approval_callback:  rubber_stamp,
  read_only:          false, 
  name:               'rw_emr', 
  models:             [Clinician]
)

# This is not working as expected.
# Suspect defect in the active_record.rb approval? method
# because the custom approval proc is not being called
result = rw_emr.run "update, replace, modify, change the last name to 'MadBomber' for the first 10 clinicians"

debug_me{[
  :result
]}

# These did not work as expected.
# emr.run "A clinician has many addresses.  how many clinicians do we have per state? return the answer as a CSV object."
# emr.run "which clinician has the most unique addresses?"
# emr.run "what are the 10 most popular first names for clinicians?"
# emr.run "A central business office (CBO) can have many keys as defined in the license_keys table.  Which central business office has the most keys."
# emr.run "in what month were the most clinician records created?"



