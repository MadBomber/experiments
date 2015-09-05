#!/usr/bin/env ruby

require 'debug_me'
include DebugMe

require 'pathname'

require 'kmeans-clusterer'
require 'bag_of_words'
require 'optparse'


cwd = Pathname.pwd
training_data = cwd + 'training_data'



datafiles = Dir['training_data/**/*.txt']
basenames = datafiles.map {|f| File.basename(f, '.txt')}

k = datafiles.length
runs = 10

OptionParser.new do |opts|
  opts.on("-kK") {|v| k = v.to_i }
  opts.on("-rD") {|v| runs = v.to_i }
end.parse!


docs = []
doc_fileids = []

get_basename = -> (docid) {
  fileid = doc_fileids[docid]
  basenames[fileid]
}

bag = BagOfWords.new idf: true

datafiles.each_with_index do |filename, i|
  File.open(filename).each do |line|
    doc = line.chomp.to_s
    next if doc.empty?
    bag.add_doc doc
    docs << doc
    doc_fileids << i
  end
end

puts "\nClassifying #{docs.length} docs with #{bag.terms_count} unique terms into #{k} clusters:\n"
data = bag.to_matrix

start = Time.now

kmeans = KMeansClusterer.run(k, data, runs: runs, log: true)

elapsed = Time.now - start

kmeans.clusters.each do |cluster|
  puts
  puts "="*45
  cp_count = cluster.points.length
  print "== Cluster ID: #{cluster.id} has #{cp_count} document"
  print 's' if cp_count > 1
  puts
  puts

  acc = Hash.new {|h, k| h[k] = []}
  grouped_points = cluster.points.inject(acc){|hsh, p| hsh[get_basename[p.id]] << p; hsh }
  sums = grouped_points.map {|file, points| [file, points.length]}
  puts sums.map {|(k, v)| "#{k}: #{v}"}.join(', ')

  samplesize = 5
  samplesize = 2 if grouped_points.keys.length > 2
  samplesize = 1 if grouped_points.keys.length > 10

  grouped_points.each do |name, points|
    points.sample(samplesize).each do |point|
      puts "\n[#{name}] #{docs[point.id]}"
    end
  end
end

puts "\nBest of #{runs} runs (total time #{elapsed.round(2)}s):"
puts "#{k} clusters in #{kmeans.iterations} iterations, #{kmeans.runtime.round(2)}s, SSE #{kmeans.error.round(2)}"
puts "Silhouette score: #{kmeans.silhouette.round(2)}"
