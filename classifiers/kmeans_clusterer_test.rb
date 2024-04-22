#!/usr/bin/env ruby

# TODO: convert so that an entry is the entire text of the file
# TODO: access text from non-text files, ;ets see how it works with large entries.
# TODO: Add CliHelper; get data files from command line; allow directory recursion
# TODO: allow for skip extensions - extensions of files to be skipped

require 'amazing_print'

require 'debug_me'
include DebugMe

require 'cli_helper'
include CliHelper

require 'pathname'

require 'kmeans-clusterer'

# from my lib/ruby
require 'bag_of_words'

configatron.version = '0.0.1'

# just using text files to make things easier
default_datafiles = Dir['training_data/**/*.txt']


HELP = <<EOHELP
Important:

  I'm not sure that I like k-means for document clustering.

  The kmeans-clusterer library relies upon everthing being in memory.

EOHELP

cli_helper("Cluster Some Documents") do |o|

  o.int     '-r', '--max_runs',    			'Maximum Number Of Runs To Perform', 	default: 10
  o.int 	'-c', '--target_cluster_size',  'Target Cluster Size',   				default: 5
  o.paths   '-f', '--files',  'Files to Cluster', default: default_datafiles.map{|f| Pathname.new f}

end

# Display the usage info
if  ARGV.empty?
  show_usage
  exit
end


# Error check you stuff; use error('some message') and warning('some message')

abort_if_errors


max_runs 			= configatron.max_runs
target_cluster_size = configatron.target_cluster_size
datafiles 			= configatron.files
basenames           = datafiles.map {|f| f.basename.to_s.gsub(f.extname,'')}


docs = [] 			# docs is really text entries (ie lines or paragraphs) from a document
doc_fileids = []    # index to the actual file from which the line|paragraph came

bag = BagOfWords.new idf: true


######################################################
# Local methods


get_basename = -> (docid) {
  fileid = doc_fileids[docid]
  basenames[fileid]
}


######################################################
# Main

at_exit do
  puts
  puts "Done."
  puts
end

ap configatron.to_h  if verbose? || debug?



# bring all the files into memory

datafiles.each_with_index do |path_name, i|
  doc = path_name.read
  next if doc.empty?
  bag.add_doc doc
  docs << doc
  doc_fileids << i
end



puts "\nClassifying #{docs.length} entries with #{bag.terms_count} unique terms into #{target_cluster_size} clusters:\n"
data = bag.to_matrix


# Discover Clusters

start 	= Time.now
kmeans 	= KMeansClusterer.run(target_cluster_size, data, runs: max_runs, log: true)
elapsed = Time.now - start


ap kmeans

#ap kmeans.methods

interesting_methods = [
	#:centroids,
	:clusters,
	#:data,
	:distances,
	:iterations,
	:k,
	:points,
	#:predict(data),
	:run,
	:runtime,
	:silhouette
]

interesting_methods.each do |i_method|
	puts
	puts "="*45
	puts "== Method: #{i_method}"
	result = kmeans.send(i_method)
	puts "Result: #{result}"
end


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


