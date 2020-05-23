#!/usr/bin/env ruby
# doit.rb

require 'pathname'
require 'awesome_print'
require 'active_support/all'

RR        = Pathname.new ENV['RR']
BASE_DIR  = RR + 'app/models/report_data/stats'

EXCEPT    = %w[ base job ]

KEYWORD   = 'template'
KEYWORD2  = '__methods__'
KLASS     = KEYWORD.titlecase

TEMPLATE  = 'template_spec.xx'
SOURCE    = Pathname.new(TEMPLATE).read

files     = BASE_DIR.children.select{|c| c.file?}

ap KEYWORD
ap TEMPLATE
ap SOURCE

ap files

def get_method_tests(from_file)
  source = from_file.read
            .split("\n")
            .map{|line| line.strip}
            .select{|line| line.start_with? 'def '}
            .map{|line| line.split(' ')[1]}

  result = ''
  source.each do |method_name|
    result += <<EOS
  it ".#{method_name}" do
    # TODO: test the #{method_name} method
  end

EOS
  end
  return result     
end


files.each do |a_file|
  method_tests    = get_method_tests(a_file)

  puts
  puts a_file
  ap method_tests

  target          = a_file.basename.to_s.gsub('.rb','')

  if EXCEPT.include? target
    puts "skipping #{target} ..."
    next
  end

  target_filename = TEMPLATE.gsub(KEYWORD, target).gsub('xx', 'rb')
  file            = Pathname.pwd + target_filename
  file.write SOURCE.gsub(KEYWORD, target).gsub(KEYWORD2, method_tests)
end
