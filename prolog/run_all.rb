#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs every demo on every installed Prolog system, shows each demo's
# output once, and reports whether the systems agree and how long each took.
#
#   ruby run_all.rb            # all demos
#   ruby run_all.rb queens     # only demos whose name contains "queens"

require 'open3'
require 'benchmark'

ROOT = __dir__

SYSTEMS = {
  'swi-prolog'     => ->(files) { ['swipl', '-q', *files] },
  'gnu-prolog'     => ->(files) { ['gprolog', *files.flat_map { |f| ['--consult-file', f] }] },
  'scryer-prolog'  => ->(files) { ['scryer-prolog', *files] },
  'trealla-prolog' => ->(files) { ['tpl', *files] }
}.freeze

# The constraint demo loads a different dialect file per system because the
# finite-domain libraries differ; each is followed by the shared puzzle.pl.
CONSTRAINT_DIALECT = {
  'swi-prolog'     => 'swi.pl',
  'gnu-prolog'     => 'gnu.pl',
  'scryer-prolog'  => 'clpz.pl',
  'trealla-prolog' => 'clpz.pl'
}.freeze

Result = Struct.new(:system, :output, :seconds, :ok)

# GNU Prolog prints a banner and compile messages before the program runs.
def strip_gprolog_noise(text)
  lines = text.lines
  last_noise = lines.rindex { |line| line.match?(/ compiled, \d+ lines read/) }
  last_noise ? lines[(last_noise + 1)..].join : text
end

def clean(system, text)
  text = strip_gprolog_noise(text) if system == 'gnu-prolog'
  text.rstrip.sub(/\A\n+/, '')
end

def run_one(system, dir, files)
  output = nil
  status = nil
  seconds = Benchmark.realtime do
    output, status = Open3.capture2e(*SYSTEMS[system].call(files), chdir: dir, stdin_data: '')
  end
  Result.new(system, clean(system, output), seconds, status.success?)
end

def demos
  portable = Dir[File.join(ROOT, 'portable', '*.pl')].sort.map do |path|
    name = File.basename(path, '.pl')
    [name, SYSTEMS.keys.to_h { |system| [system, [File.dirname(path), [File.basename(path)]]] }]
  end
  constraints = ['sendmore (constraints)',
                 CONSTRAINT_DIALECT.transform_values { |file| [File.join(ROOT, 'constraints'), [file, 'puzzle.pl']] }]
  portable + [constraints]
end

def verdict(result, reference)
  return 'FAILED' unless result.ok

  result.output == reference ? 'same output' : 'DIFFERENT OUTPUT'
end

def report(name, results)
  reference = results.first.output
  rows = results.map do |r|
    format('  %-15s %7.0f ms   %s', r.system, r.seconds * 1000, verdict(r, reference))
  end

  puts <<~REPORT
    #{'=' * 70}
    #{name}
    #{'=' * 70}
    #{reference}

    #{rows.join("\n")}

  REPORT

  results.reject { |r| r.ok && r.output == reference }.each do |r|
    puts "--- #{r.system} printed:\n#{r.output}\n\n"
  end
end

filter = ARGV.first
all_agree = true

demos.each do |name, targets|
  next if filter && !name.include?(filter)

  results = targets.map { |system, (dir, files)| run_one(system, dir, files) }
  report(name, results)
  all_agree &&= results.all? { |r| r.ok && r.output == results.first.output }
end

exit(all_agree ? 0 : 1)
