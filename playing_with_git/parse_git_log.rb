#!/usr/bin/env ruby
# encoding: utf-8
##########################################################
###
##  File: parse_git_log.rb
##  Desc: Parse result of "git log --name-status" into separate JSON files
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#
require 'Pathname'
require 'awesome_print'
require 'date'

require 'debug_me'
include DebugMe

# Adding a little sugar to String to support
# duck typing requirement of the extract_jira_tickets method

class String
  def join
    self
  end
end


usage = <<EOS

Parse a git-based working directory's log file
then do something with it in another program.

Usage: #{__FILE__} [working_directory]

Where:

  working_directory   [optional] is a git-managed working directory
                      Default Value: #{Pathname.pwd}

EOS

if  ARGV.include?('--help')  ||
    ARGV.include?('-h')      ||
    ARGV.include?('-?')
  puts usage
  exit
end

git_log_command = 'git'

unless ARGV.empty?
  working_directory = Pathname.new ARGV.shift
  unless  working_directory.exist?  &&
          working_directory.directory?
    puts "\nERROR: Argument is not an existing directory."
    puts usage
    exit
  end
  git_log_command += " -C #{working_directory}"
end

git_log_command += ' log --name-status'


def is_a_merge(an_array)
  merge_string_index = an_array.index{|s| s.start_with?("Merge")}
  return !merge_string_index.nil?
end


def extract_date(an_array)
  date_string_index = an_array.index{|s| s.start_with?("Date:")}
  date_string = an_array[date_string_index]
  return DateTime.parse date_string.gsub('Date:','').strip
end


def extract_author(an_array)
  author_string_index = an_array.index{|s| s.start_with?("Author:")}
  author_string = an_array[author_string_index]
  return author_string.gsub('Author:','').strip
end


def extract_files(an_array)
  files = []
  an_array.reverse.each do |a_file|
    next if a_file.empty?
    next if a_file.start_with?(' ')
    break if a_file.start_with?('Date:')
    files << a_file.split("\t").last
  end
  return files.sort
end


def extract_description(an_array)
  description = ""
  while !an_array.shift.empty? do
    # NOOP
  end

  until an_array.first.empty? do
     description << an_array.shift.strip + "\n"
  end

  return description.chomp
end


# from can be a string or an array of strings
def extract_jira_tickets(projects: ['PP', 'DEAP', 'CUI'], from:)
  minmax_string   = projects.map{|x|x.size}.minmax.join(',')
  project_string  = projects.join + projects.join.downcase
  project_string  = project_string.scan(/\w/).uniq.sort.join
  regex_string    = "([#{project_string}]{#{minmax_string}}-" + '\d+)'
  jira_re         = Regexp.new(regex_string)
  jira_tickets    = from.join(' ').scan(jira_re).flatten.map{|t|t.upcase}.sort.uniq
  return jira_tickets
end


def parse_pull_request(a_string)
  pr_details    = /^\s.*#(?<id>\d+) in (?<repo>.*) from (?<source>.*) to (?<target>.*)$/.match(a_string)
  pull_request  = Hash[ pr_details.names.map{|k|k.to_sym}.zip( pr_details.captures ) ]
  return pull_request
end


def extract_pull_request(an_array)
  pr_string_index = an_array.index{|s| s.include?("Merge pull request")}
  pull_request = pr_string_index.nil? ? {} : parse_pull_request(an_array[pr_string_index])
  return pull_request
end


def parse_commit(an_array)
  commit_id     = an_array.first.split().last
  date          = extract_date(an_array)
  author        = extract_author(an_array)
  merge         = is_a_merge(an_array)
  pull_request  = merge ? extract_pull_request(an_array) : {}
  files         = extract_files(an_array)
  description   = extract_description(an_array)
  jira_tickets  = extract_jira_tickets from: [pull_request[:source], description]

  return {
    id:           commit_id,
    date:         date,
    author:       author,
    merge:        merge,
    pull_request: pull_request,
    files:        files,
    description:  description,
    jira_tickets: jira_tickets
  }
end


######################################################
# Main

result = `#{git_log_command}`.split("\n")

max_commits   = 3000
commit_count  = 0
line_count    = 0

commit_start_index  = 0
commit_stop_index   = 0

result.each do |a_line|
  if a_line.start_with?('commit')
    commit_count += 1

    commit_start_index  = commit_stop_index + 1
    commit_stop_index   = line_count - 1

    unless commit_stop_index <= commit_start_index
      commit = parse_commit(result[commit_start_index .. commit_stop_index])
      puts "\n" + "-"*65
      ap commit
    end
    exit if commit_count >= max_commits
  end
  line_count += 1
end

