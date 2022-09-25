#!/usr/bin/env ruby
# experiments/ruby_misc/playing_with_tr.rb
# according to rastruby.io `tr` is faster than `gsub`
# when dealing with pure String objects
#
# Also evaluating the telephone_number gem

require 'pathname'
require 'bundler/inline'

print "Installing gems as necessary ... "
gemfile do
    source 'https://rubygems.org'
    gem 'telephone_number'
end

puts 'done'

COUNTRY     = :US
VALID_TYPES = %i[
    area_code_optional
    fixed_line
    mobile
    no_international_dialling
    pager
    personal_number
    premium_rate
    shared_cost
    toll_free
    uan
    voicemail
    voip
]

data_path = Pathname.pwd + 'data.txt'

class String
  # TODO: Consider making this a refinement
  def to_phone_digits
    self.downcase
        .tr('abc',  '2')  # characters from iPhone display
        .tr('def',  '3')
        .tr('ghi',  '4')
        .tr('jkl',  '5')
        .tr('mno',  '6')
        .tr('pqrs', '7')
        .tr('tuv',  '8')
        .tr('wxyz', '9')
        .tr('+',    '0')
  end
end

line_number = 0

data_path.readlines.each do |a_string|
  line_number += 1

  canidate = a_string.chomp

  print "#{line_number}: #{canidate} -=> "

  digits  = canidate.to_phone_digits

  print "#{digits} is "

  phone_number  = TelephoneNumber.parse(digits, COUNTRY)

  if phone_number.valid?(VALID_TYPES)
    comment = phone_number.national_number
  else
    comment = "** bad **"
    print "NOT "
  end

  puts "a valid #{COUNTRY} phone number.  #{comment}"
end
