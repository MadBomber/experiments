#!/usr/bin/env ruby
# frozen_string_literal: true

# Homebrew ships Trealla as a static library (libtrealla.a), which Fiddle
# cannot load.  This relinks it into build/libtrealla.dylib.
#
#   ruby build.rb
#
# Override the locations with TREALLA_PREFIX and OPENSSL_PREFIX if needed.

require 'fileutils'

TREALLA_PREFIX = ENV.fetch('TREALLA_PREFIX', '/opt/homebrew/opt/trealla-prolog')
OPENSSL_PREFIX = ENV.fetch('OPENSSL_PREFIX', '/opt/homebrew/opt/openssl@4')

ARCHIVE = File.join(TREALLA_PREFIX, 'lib', 'libtrealla.a')
OUTPUT  = File.join(__dir__, 'build', 'libtrealla.dylib')

# -force_load keeps every object in the archive; without it the linker
# drops them all, because nothing in an empty dylib refers to them.
def link_command(archive, output, openssl_prefix)
  ['cc', '-shared', '-o', output,
   "-Wl,-force_load,#{archive}",
   '-ledit', '-lffi',
   "-L#{File.join(openssl_prefix, 'lib')}", '-lssl', '-lcrypto']
end

abort "missing #{ARCHIVE} (brew install trealla-prolog)" unless File.exist?(ARCHIVE)

FileUtils.mkdir_p(File.dirname(OUTPUT))
system(*link_command(ARCHIVE, OUTPUT, OPENSSL_PREFIX)) || abort('link failed')
puts "built #{OUTPUT}"
