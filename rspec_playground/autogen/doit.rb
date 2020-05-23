#!/usr/bin/env ruby
# doit.rb

require 'pathname'
require 'awesome_print'
require 'active_support/all'

EXCEPT    = %w[ base job worker ]

RR        = Pathname.new ENV['RR']
BASE_DIR  = RR + 'app/models/report_data'

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


def get_method_tests(from_file)
  source = from_file.read
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
  target        = a_file.basename.to_s.gsub('.rb','')

  if EXCEPT.include? target
    puts "=============== skipping #{target} ..."
    next
  end

  dir = Pathname.pwd + target

  puts "doing #{target} in #{dir}"

  method_tests    = get_method_tests(a_file)

  klass           = target.camelcase
  target_filename = TEMPLATE.gsub(KEYWORD, target).gsub('xx', 'rb')
  file            = dir + target_filename
  file.write SOURCE.gsub(KEYWORD, target).gsub(KLASS, klass).gsub(KEYWORD2, method_tests)
end
