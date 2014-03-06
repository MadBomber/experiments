#!/usr/bin/env ruby -W0
##########################################################
###
##  File: translation_test.rb
##  Desc: Test out some of the common translation gems
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'debug_me'

require 'pathname'

require 'multi_translate'
require 'easy_translate'
require 'google_translate'


me        = Pathname.new(__FILE__).realpath
my_dir    = me.parent
my_name   = me.basename.to_s

$options = {
  verbose:        false
}

def verbose?
  $options[:verbose]
end

usage = <<EOS

Test out some of the common translation gems

Usage: #{my_name} options

Where:

  options               Do This
    -h or --help        Display this message
    -v or --verbose     Display progress

EOS

# Check command line for Problems with Parameters
errors = []

if  ARGV.empty?               ||
    ARGV.include?('-h')       ||
    ARGV.include?('--help')
  puts usage
  exit
end

%w[ -v --verbose ].each do |param|
  if ARGV.include? param
    $options[:verbose] = true
    ARGV[ ARGV.index(param) ] = nil
  end
end


# ...


ARGV.compact!

unless errors.empty?
  STDERR.puts
  STDERR.puts "Correct the following errors and try again:"
  STDERR.puts
  errors.each do |e|
    STDERR.puts "\t#{e}"
  end
  STDERR.puts
  exit(1)
end


######################################################
# Local methods

source = <<EOS
MeditationDate: Thursday, March 6th, 2014
Title:True Guests
LongReading: Read Luke 14:15-24
QuotedScripture: The master said to the slave, “Go out into the roads and lanes, and compel people to come in, so that my house may be filled.”
Citation: - Luke 14:23 (NRSV)
BodyText: The members of the church had chosen to bring in the new year with a worship service that night. Ahead of time, many had declined to come, saying they had other places to go and people to visit. By midnight, no one had arrived. I was sad because I had spent a great deal of time preparing the program. Soon a young boy who attends Sunday school came by. He said, “Pastor, let’s go ahead with the service.” I said, “I don’t think so. No one is here.” The young boy looked at me and said, “But three of us are here — you, me and Jesus.” (See Matt. 18:20.) I realized that the purpose of this service was not simply to gather the people but to worship God and receive God’s blessings. After we sang a few joyous songs, neighbors from the area began to join us. It was a spirit-filled night, and many came to know Christ. This experience reminded me of the parable of the great dinner in Luke 14. After the host sent the invitations and received the news that the guests were not coming, he extended the invitation to include people from the “roads and lanes.” Our dinner became a true feast, where those who came truly wanted to be there. And they were fed by the Bread of Life, Jesus Christ.
Author: Dennis Rojas (Ica, Peru)
TFTD: God often changes our plans for the better.
Prayer: Dear loving Father, thank you for allowing us to come to your house and to sit at table with you. Amen.
Prayer Focus: Those who live near my church
EOS


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

puts "="*45
puts "source"
puts

puts source


=begin

rescue Exception => e

end
puts "="*45
puts "multi-translate: Google"
puts

mtg_target = MultiTranslate.translate(MultiTranslate::Engines::GOOGLE, 'en', 'es', source)

puts mtg_target

=end

puts "="*45
puts "multi-translate: Apertium"
puts "A free/open-source machine translation platform"
puts

mta_target = MultiTranslate.translate(MultiTranslate::Engines::APERTIUM, 'en', 'es', source)

puts mta_target


__END__

puts "="*45
puts "easy_translate"
puts

et_target = "Requres a Google API key" # EasyTranslate.translate(source, :to => :spanish)

puts et_target




puts "="*45
puts "google-translate"
puts

glate = GoogleTranslate.new

gt_target_array = glate.translate(:en, :es, source)

puts gt_target_array.class

puts <<EOS
  The Google Translation API (v2) is a paid service.
  Cost is approximately $20 per 1 million translated characters.

  returns an array of size: #{gt_target_array.size}
  array.first is an array of the translation and the source
    each element has 4 members
      0: translation
      1: source
      2: Translit
      3:

  The source string is broken up by Google Translate into sentences.
  The array that is returned is compartmented by the sentences.

  Here is the Meditation Date and Title:
    #{gt_target_array[0][0].first.strip}
    #{gt_target_array[0][1].first.strip}

EOS








