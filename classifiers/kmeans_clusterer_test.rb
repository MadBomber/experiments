#!/usr/bin/env ruby

# TODO: convert so that an entry is the entire text of the file
# TODO: access text from non-text files, ;ets see how it works with large entries.
# TODO: Add CliHelper; get data files from command line; allow directory recursion
# TODO: allow for skip extensions - extensions of files to be skipped

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

require 'pathname'

require 'kmeans-clusterer'
require 'bag_of_words'
require 'optparse'


cwd = Pathname.pwd
training_data = cwd + 'training_data'


# just using text files to make things easier
datafiles = Dir['training_data/**/*.txt']
basenames = datafiles.map {|f| File.basename(f, '.txt')}

target_cluster_size = datafiles.length
max_runs = 10

OptionParser.new do |opts|
  opts.on("-kK") {|v| target_cluster_size = v.to_i }
  opts.on("-rD") {|v| max_runs = v.to_i }
end.parse!


docs = [] 			# docs is really text entries (ie lines or paragraphs) from a document
doc_fileids = []    # index to the actual file from which the line|paragraph came

get_basename = -> (docid) {
  fileid = doc_fileids[docid]
  basenames[fileid]
}

bag = BagOfWords.new idf: true


# bring all the entries from all the files into memory

datafiles.each_with_index do |filename, i|
  File.open(filename).each do |line|
    doc = line.chomp
    next if doc.empty?
    bag.add_doc doc
    docs << doc
    doc_fileids << i
  end
end

puts "\nClassifying #{docs.length} entries with #{bag.terms_count} unique terms into #{target_cluster_size} clusters:\n"
data = bag.to_matrix


# Discover Clusters

start 	= Time.now
kmeans 	= KMeansClusterer.run(target_cluster_size, data, runs: max_runs, log: true)
elapsed = Time.now - start


# Report the results

kmeans.clusters.each do |cluster|
  puts
  puts "="*45
  cp_count = cluster.points.length
  print "== Cluster ID: #{cluster.id} has #{cp_count} entr"
  print (cp_count > 1 ? 'ies' : 'y')
  puts
  puts

  acc = Hash.new {|h, k| h[k] = []}

  grouped_points = cluster.points.inject(acc){|hsh, p| hsh[get_basename[p.id]] << p; hsh }

  sums = grouped_points.map {|file, points| [file, points.length]}
  
  puts sums.map {|(k, v)| "#{k}: #{v}"}.join(', ')

  sample_size = 5
  sample_size = 2 if grouped_points.keys.length > 2
  sample_size = 1 if grouped_points.keys.length > 10

  grouped_points.each do | file_basename, points |

    points.sample(sample_size).each do |point|
      puts "\n[#{file_basename}] #{docs[point.id]}"
    end

  end
end

puts
puts
puts "="*45
puts "== Recap"
puts

puts "Best of #{max_runs} runs (total time #{elapsed} seconds)"
puts
puts "  Cluster size: #{target_cluster_size} clusters"
puts "    Iterations: #{kmeans.iterations}"
puts "      Run-time: #{kmeans.runtime} seconds"
puts
puts "  k-means Error (SSE): #{kmeans.error}"
puts "     Silhouette score: #{kmeans.silhouette}"

puts


