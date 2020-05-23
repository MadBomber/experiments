#!/usr/bin/env ruby
# doit.rb

require 'pathname'
require 'awesome_print'
require 'active_support/all'

RR        = Pathname.new ENV['RR']
BASE_DIR  = RR + 'app/models/report_data/billable'

EXCEPT    = %w[ base job ]

KEYWORD   = 'template'
KEYWORD2  = '__methods__'
KLASS     = KEYWORD.titlecase

TEMPLATE  = 'template_spec.xx'
SOURCE    = Pathname.new(TEMPLATE).read

files     = BASE_DIR.children.select{|c| c.file?}

ap KEYWORD
ap KEYWORD2
ap TEMPLATE
ap SOURCE

ap files.map{|d| d.basename.to_s}


def get_method_tests(a_string)
  source = a_string
            .split("\n")
            .map{|line| line.strip}
            .select{|line| line.start_with? 'def '}
            .map{|line| line.split(' ')[1]}
            .reject{|m| m.start_with?('initialize')}

  result = ''
  source.each do |method_name|
    result += <<EOS
  # TODO: test the Template.#{method_name} method
  it ".#{method_name}"

EOS
  end
  return result
end


files.each do |a_file|
  business_logic  = a_file.read
  method_tests    = get_method_tests(business_logic)
  target          = a_file.basename.to_s.gsub('.rb','')

  if EXCEPT.include? target
    puts "=============== skipping #{target} ..."
    next
  end

  target_filename = TEMPLATE.gsub(KEYWORD, target).gsub('xx', 'rb')
  file            = File.open(Pathname.pwd + target_filename, 'w')
  file.puts SOURCE.gsub(KEYWORD, target).gsub(KEYWORD2, method_tests)
  file.puts "\n\n__END__\n\n"
  file.puts business_logic
  file.close
end
