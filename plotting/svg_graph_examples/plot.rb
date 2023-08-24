#!/usr/bin/env ruby
# lib/patches/examples/plot.rb

require 'svggraph'

# Data sets are x,y pairs
# Note that multiple data sets can differ in length, and that the
# data in the datasets needn't be in order; they will be ordered
# by the plot along the X-axis.
projection = [
  6, 11,    0, 5,   18, 7,   1, 11,   13, 9,   1, 2,   19, 0,   3, 13,
  7, 9
]
actual = [
  0, 18,    8, 15,    9, 4,   18, 14,   10, 2,   11, 6,  14, 12,
  15, 6,   4, 17,   2, 12
]

graph = SVG::Graph::Plot.new(
	{
		:height 						=> 500,
		:width 							=> 300,
		:key 								=> true,
		:scale_x_integers 	=> true,
		:scale_y_integerrs 	=> true,
	}
)

graph.add_data(
	{
    :data 	=> projection,
  	:title 	=> 'Projected',
	}
)

graph.add_data(
	{
    :data => actual,
  	:title => 'Actual',
	}
)

print graph.burn()
