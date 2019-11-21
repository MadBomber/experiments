#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: table_read.rb
##  Desc: Conduct a rable read of a spec script
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

configatron.version = '0.0.1'

require 'json'

ACTORS = {
  english: {
    female: [
      { name: 'Allison'  , accent: 'American'       , type: 'en_US',       test: "Hello, my name is Allison. I am an American-English voice."},
      { name: 'Ava'      , accent: 'American'       , type: 'en_US',       test: "Hello, my name is Ava. I am an American-English voice."},
      { name: 'Fiona'    , accent: 'Scotish'        , type: 'en-scotland', test: "Hello, my name is Fiona. I am a Scottish-English voice."},
      { name: 'Karen'    , accent: 'Austrian'       , type: 'en_AU',       test: "Hello, my name is Karen. I am an Australian-English voice."},
      { name: 'Kate'     , accent: 'British'        , type: 'en_GB',       test: "Hello, my name is Kate. I am a British-English voice."},
      { name: 'Moira'    , accent: 'Irish'          , type: 'en_IE',       test: "Hello, my name is Moira. I am an Irish-English voice."},
      { name: 'Samantha' , accent: 'American'       , type: 'en_US',       test: "Hello, my name is Samantha. I am an American-English voice."},
      { name: 'Serena'   , accent: 'British'        , type: 'en_GB',       test: "Hello, my name is Serena. I am a British-English voice."},
      { name: 'Susan'    , accent: 'American'       , type: 'en_US',       test: "Hello, my name is Susan. I am an American-English voice."},
      { name: 'Tessa'    , accent: 'South African'  , type: 'en_ZA',       test: "Hello, my name is Tessa. I am a South African-English voice."},
      { name: 'Veena'    , accent: 'Indian'         , type: 'en_IN',       test: "Hello, my name is Veena. I am an Indian-English voice."},
      { name: 'Victoria' , accent: 'American'       , type: 'en_US',       test: "Hello, my name is Victoria. Isn''t it nice to have a computer that will talk to you?"},
    ],
    male: [
      { name: 'Alex'     , accent: 'American'       , type: 'en_US',       test: "Hello, my name is Alex. Most people recognize me by my voice."},
      { name: 'Daniel'   , accent: 'British'        , type: 'en_GB',       test: "Hello, my name is Daniel. I am a British-English voice."},
      { name: 'Fred'     , accent: 'American'       , type: 'en_US',       test: "Hello, my name is Fred. I sure like being inside this fancy computer"},
      { name: 'Oliver'   , accent: 'British'        , type: 'en_GB',       test: "Hello, my name is Oliver. I am a British-English voice."},
      { name: 'Tom'      , accent: 'American'       , type: 'en_US',       test: "Hello, my name is Tom. I am an American-English voice."},
    ]
  }
}



HELP = <<EOHELP
Important:

  Put important stuff here.

EOHELP

=begin
cli_helper("Conduct a rable read of a spec script") do |o|

  o.bool    '-b', '--bool',   'example boolean parameter',   default: false
  o.string  '-s', '--string', 'example string parameter',    default: 'IamDefault'
  o.int     '-i', '--int',    'example integer parameter',   default: 42
  o.float   '-f', '--float',  'example float parameter',     default: 123.456
  o.array   '-a', '--array',  'example array parameter',     default: [:bob, :carol, :ted, :alice]
  o.path    '-p', '--path',   'example Pathname parameter',  default: Pathname.new('default/path/to/file.txt')
  o.paths         '--paths',  'example Pathnames parameter', default: ['default/path/to/file.txt', 'file2.txt'].map{|f| Pathname.new f}

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check your stuff; use error('some message') and warning('some message')

configatron.input_files = get_pathnames_from( configatron.arguments, '.txt')

if configatron.input_files.empty?
  error 'No text files were provided'
end

abort_if_errors

=end

######################################################
# Local methods

require_relative './talent_pool'
require_relative './spec_script'

######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

# ap configatron.to_h  if verbose? || debug?

COMMAND = 'say -v'

results = `#{COMMAND} '?'`.split("\n")

voices = {}

talent_pool = TalentPool.new

talent_pool.show

__END__

puts "The following languages are available:"
puts ACTORS.keys.sort.join(', ')

language = :english

puts "For #{language} the following genders are available:"
puts ACTORS[language].keys.sort.join(', ')

gender = :female

puts "For #{language} #{gender} the following accents are available:"
puts ACTORS[language][gender].map{|entry| entry[:accent]}.sort.uniq.join(', ')

puts "here are all of the #{language} #{gender} actors voice samples:"

# ACTORS[language][gender].each do |actor|
#   puts "Actor: #{actor[:name]}"
#   command = "#{COMMAND} #{actor[:name]} #{actor[:test]}"
#   system command
# end


gender = :male

puts "\n\nFor #{language} #{gender} the following accents are available:"
puts ACTORS[language][gender].map{|entry| entry[:accent]}.sort.uniq.join(', ')

puts "here are all of the #{language} #{gender} actors voice samples:"

# ACTORS[language][gender].each do |actor|
#   puts "Actor: #{actor[:name]}"
#   command = "#{COMMAND} #{actor[:name]} #{actor[:test]}"
#   system command
# end



cast  = {
          direction: 'Daniel',
          ELLIE:     'Allison',
          GRANT:     'Tom',
          VOLUNTER: 'Susan',
        }


script = [



# EXT THE DIG DAY

  {direction: "Exterior - the dig day"},

  {direction: "An artist's camel hair brush carefully sweeps away sand and rock
      to slowly reveal the dark curve of a fossil - it's a claw.  A dentist's
      pick gently lifts it from the place its has laid for millions of years.
      Pull up to reveal a group of diggers working on a large skeleton.  All
      we see are the tops of their hats.  The paleontologist working on the
      claw lays it in his hand."},

        {direction: "GRANT
                      (thoughtfully)"},
    {GRANT: "Four complete skeletons. . . .
            such a small area. . .
            the same time horizon - -"},

        {ELLIE:
    "They died together?"},

        {GRANT:
    "The taphonomy sure looks that way."},

        {ELLIE: "If they died together, they lived together.
                    Suggests some kind of social order."},

  {direction: "DR ALAN GRANT, mid-thirties, a ragged-looking guy with intense
      concentration you wouldn't want to get in the way of, carefully
      examines a claw.

      DR ELLIE SATTLER, working with him, leans in close and studies
      it too.  She paints the exposed bone with rubber cement.  Ellie in her
      late twenties, athletic-looking.  There's an impatience about Ellie, as
      if nothing in life happens quite fast enough for her.

      Her face is almost pressed up against his, she's sitting so
      close."},

        {GRANT: "They hunted as a team.  The dismembered tenontosaurus
                    bone over there - that's lunch.  But what killed our
                    raptors in a lakebed, in a bunch like this?  We better
                    come up with something that makes sense."},

        {ELLIE:
    "A drought.  The lake was shrinking "},

        {direction: "GRANT
                      (excited)"},
    {GRANT: "That's good.  That's right!  They died around a dried-up
            puddle!  Without fighting each other.  This is looking
            good."},

  {direction: "From the bottom of the hill a voice SHOUTS to them:"},

        # VOLUNTERR (o.s.)
        {direction: "volunteer off screen"},
    {VOLUNTER: "Dr Grant!  Dr Sattler!  We're ready to try again!"},

  {direction: "Grant SIGNS and sits up, stretching out his back."},

        {GRANT:
    "I hate computers."},

]

ap cast

ap script



script.each do |entry|
  character = entry.keys.first
  line      = entry[character].gsub("\n",' ').gsub('-', '').gsub('(','').gsub(')','').gsub("'","''")


  puts "\n#{character}: #{line}"
  command = "#{COMMAND} #{cast[character]} #{line}"
  system command
end