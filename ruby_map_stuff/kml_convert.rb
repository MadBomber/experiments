#!/usr/bin/ruby -w

=begin
/***************************************************************************
 *   Copyright (C) 2008, Paul Lutus                                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/
=end

PVERSION = 1.1

# version 1.1 deals with path descriptions
# as well as isolated position sets

class KmlConvert

   XML_HEADER = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

   TAB_STR = "\t"

   def beautifyXML(data)
      tab = 0
      xml = []
      data.split("\n").each { |record|
         record.strip!
         if(record.size > 0)
            outc = record.scan(%r{(</|/>)}).length
            inc = record.scan(%r{<\w}).length
            net = inc - outc
            tab += (net < 0)?net:0
            xml << (TAB_STR * tab) + record
            tab += (net > 0)?net:0
         end
      }
      return xml.join("\n")
   end

   def wrap_tag(data,tag,extension = "",linefeed = false)
      lf = (linefeed)?"\n":""
      if(extension.size > 0)
         return "<#{tag} #{extension}>#{lf}#{data}</#{tag}>\n"
      else
         return "<#{tag}>#{lf}#{data}</#{tag}>\n"
      end
   end

   def get_tag_content(data,arg)
      if(data =~ %r{#{arg}}im)
         result = data.sub(%r{.*<#{arg}>(.*?)</#{arg}>.*}im,"\\1")
      else
         result = ""
      end
      return result.strip
   end

   def kml_csv(array)
      array.join("\n").scan(%r{<Placemark>.*?</Placemark>}im) do |record|
         name = get_tag_content(record,"name")
         desc = get_tag_content(record,"description")
         coord = get_tag_content(record,"coordinates")
         multipos = coord.split(%r{\s+}im)
         if(multipos.size > 1) # if a path of connected positions
            n = 0
            multipos.each do |pos|
               num_tag = sprintf("%03d",n)
               lng,lat,alt = pos.split(",")
               puts "#{lat},#{lng},#{alt},#{name + "_" + num_tag},#{num_tag}"
               n += 1
            end # each position on a path
         else # one or more unconnected positions
            lng,lat,alt = coord.split(",")
            puts "#{lat},#{lng},#{alt},#{name},#{desc}"
         end
      end # each record
   end # kml_csv

   def csv_kml(array)
      xml = []
      xml << wrap_tag("1","open")
      array.each do |record|
         record.strip!
         output = []
         lat,lng,alt,name,desc = record.split(",")
         output << wrap_tag(name,"name")
         output << wrap_tag(desc,"description")
         coord = wrap_tag("#{lng},#{lat},#{alt}","coordinates")
         output << wrap_tag(coord,"Point","",true)
         xml << wrap_tag(output.join("\n"),"Placemark","",true)
      end # each record
      data = wrap_tag(xml.join("\n"),"Folder","",true)
      data = wrap_tag(data,"Document","",true)
      data = wrap_tag(data,"kml","xmlns=\"http://earth.google.com/kml/2.2\"",true)
      puts XML_HEADER + "\n" + beautifyXML(data)
   end # csv_kml

   def process()
      data = $stdin.readlines
      if (data[0] =~ %r{<?xml}) # if KML input, CSV output
         kml_csv(data)
      else # CSV input, KML output
         csv_kml(data)
      end
   end # process
end # class KmlConvert

# usage: script_name.rb < input_file > output_file
# autodetects the conversion direction
# CSV -> KML or KML -> CSV

KmlConvert.new.process()