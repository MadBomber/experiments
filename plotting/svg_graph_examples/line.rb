#!/usr/bin/env ruby -wKU
# lib/patches/examples/line.rb


require 'svggraph'

fields        = %w(Jan Feb Mar);
data_sales_02 = [12, 45, 21]
data_sales_03 = [15, 30, 40]

graph = SVG::Graph::Line.new(
  {
    :height => 500,
    :width  => 300,
    :fields => fields,
  }
)

graph.add_data(
  {
    :data   => data_sales_02,
    :title  => 'Sales 2002',
  }
)

graph.add_data(
  {
    :data   => data_sales_03,
    :title  => 'Sales 2003',
  }
)

print "Content-type: image/svg+xml\r\n\r\n";
print graph.burn();
