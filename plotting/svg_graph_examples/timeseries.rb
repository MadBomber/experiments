#!/usr/bin/env ruby
# lib/patches/examples/timeseries.rb

require 'debug_me'
include DebugMe

require 'date'
require 'svggraph'

# Data sets are x,y pairs
data1 = [
          "72/06/17", 11,
          "72/01/11", 7,
          "99/04/13", 11,
          "99/09/11", 9,
          "85/09/01", 2,
          "88/09/01", 1,
          "95/01/15", 13
        ]
data2 = [
          "73/08/01", 18,
          "77/03/01", 15,
          "98/10/01", 4,
          "02/05/01", 14,
          "95/03/01", 6,
          "91/08/01", 12,
          "87/12/01", 6,
          "84/05/01", 17,
          "80/10/01", 12
        ]

title = "This is a Title"

graph = SVG::Graph::TimeSeries.new(
  {
    :width                  => 640,
    :height                 => 480,
    :graph_title            => title,
    :show_graph_title       => true,
    :no_css                 => true,
    :key                    => true,
    :scale_x_integers       => true,
    :scale_y_integers       => true,
    :min_x_value            => 0,
    :min_y_value            => 0,
    :show_data_labels       => true,
    :show_x_guidelines      => true,
    :show_x_title           => true,
    :x_title                => "Time",
    :show_y_title           => true,
    :y_title                => "Ice Cream Cones",
    :y_title_text_direction => :bt,
    :stagger_x_labels       => true,
    :x_label_format         => "%m/%d/%y",
  }
)

graph.add_data(
  {
    data:   data1,
    title:  'Projected'
  }
)

graph.add_data(
  {
    :data   => data2,
    :title  => 'Actual',
  }
)

print graph.burn()
