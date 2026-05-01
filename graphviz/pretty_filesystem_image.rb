#!/usr/bin/env ruby
# experiments/graphviz/pretty_filesystem_image.rb

def generate_graph(file_paths, level:2, orientation: "LR")
  graph = <<~HEADER
    digraph DirectoryStructure {
      node [shape=box];
      rankdir=#{orientation};
  HEADER

  uniq_paths = []
  file_paths.each do |file_path|
    parts = file_path.split('/')[0..level-1]
    uniq_paths << parts unless uniq_paths.last == parts
  end

  uniq_paths.each do |parts|
    parts.each_with_index do |part, index|
      break if index >= level
      
      parent = parts[0...index].join('/')
      child  = parts[0..index].join('/')
      
      new_line = " \"#{parent}\" -> \"#{child}\"\n" 

      unless parent.empty? || child.empty?
        graph << new_line unless graph.include?(new_line)
      end
    
    end
  end

  graph << "}\n"
  graph
end

def write_file(contents, filename)
  File.write(filename, contents)
end

if ARGV.empty?
  puts "Usage: #{__FILE__} filepaths.txt [-l LEVEL]"
  exit(1)
end

file_path = ARGV.shift
level = ARGV.include?("-l") ? ARGV[ARGV.index("-l") + 1].to_i : 1

begin
  file_paths = File.readlines(file_path).map(&:chomp)
rescue Errno::ENOENT
  puts "Error: File '#{file_path}' not found."
  exit(1)
end

dot_content = generate_graph(file_paths, level: level)
write_file(dot_content, 'directory_structure.dot')


__END__

  digraph organizational_chart {
  node [shape=box];

  /* Define nodes */
  CEO [label="CEO"];
  Manager1 [label="Manager 1"];
  Manager2 [label="Manager 2"];
  Employee1 [label="Employee 1"];
  Employee2 [label="Employee 2"];
  Employee3 [label="Employee 3"];
  Employee4 [label="Employee 4"];

  /* Define relationships */
  CEO -> {Manager1 Manager2}
  Manager1 -> {Employee1 Employee2}
  Manager2 -> {Employee3 Employee4}
  }



