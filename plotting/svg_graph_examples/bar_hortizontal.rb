#!/usr/bin/env ruby

  require 'svggraph'

  fields = %w(Jan Feb Mar)
  data_sales_02 = [12, 45, 21]

  graph = SVG::Graph::BarHorizontal.new({
    :height => 500,
    :width => 300,
    :fields => fields,
  })

  graph.add_data({
    :data => data_sales_02,
    :title => 'Sales 2002',
  })

  print "Content-type: image/svg+xml\r\n\r\n"
  print graph.burn
