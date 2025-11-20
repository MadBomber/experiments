require 'graphviz'

# Initialize a new Graphviz graph
g = GraphViz.new( :G, :type => :digraph )

# Add nodes
node_a = g.add_nodes("Node A")
node_b = g.add_nodes("Node B")
node_c = g.add_nodes("Node C")

# Add edges between the nodes
g.add_edges(node_a, node_b)
g.add_edges(node_b, node_c)
g.add_edges(node_c, node_a)

# Generate output in dot format
g.output( dot: "directed_graph.dot" )

# Optionally, generate a PNG image
g.output( png: "directed_graph.png" )

