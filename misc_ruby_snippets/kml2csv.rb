#############################
## kml2csv.rb

require "rexml/document"
include REXML
kmlroot = (Document.new File.new "data.kml").root
nodes = kmlroot.elements.to_a("//Location")

begin
	f = File.open("data.csv", "w")
	f << "id,column1,column2,latitude,longitude"\n"
	id = 1
	nodes.each { |node|
		column1 = node.elements["column1"].text
		column2 = node.elements["column2"].text
		coords = node.elements["Point"].elements["coordinates"].text.split(",")
		f << [id, column1, column2, coords[1], coords[0] ].join(",") << "\n"
		id += 1
	}
ensure
	f.close
end