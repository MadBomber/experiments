#!/usr/bin/ruby -w

=begin
/***************************************************************************
 *   Copyright (C) 2007, Paul Lutus                                        *
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

DEBUG=false

PVERSION = 1.3

class IcomProgrammer

   def initialize()

      @windows = (PLATFORM =~ /mswin/)

      @baud_rate = 19200 # fastest baud rate Icom radios will tolerate

      if(@windows) # Windows setup
         @ser_port = "COM1:" # default serial port, change to suit your needs
         @ser_config = "MODE #{@ser_port} baud=#{@baud_rate} parity=n data=8 stop=1"
      else # Linux setup
         @ser_port = "/dev/ttyUSB0" # default serial port, change to suit your needs
         @ser_config = "stty -F #{@ser_port} #{@baud_rate} raw -echo"
      end

      @data_directory = "frequency_data" # a subdirectory of the program's directory

=begin

Record format for radio_info_hash:
	"radio_name" => [hex_radio_code,["table_name_1","table_name_2","etc.."]],

The special name "E" means "erase remaining unused memory locations"

The file paths are constructed like this: data_directory + "/" + table_name + ".csv"

Each table is a comma-separated-value (csv) data table, like this:

Mode,RxFreq,TxFreq,RxTone,TxTone
fm,145.37,144.77,110.9,100.0

Not all data tables need all these fields. Here is a minimal table header and entry:

Mode,RxFreq
am,0.540

Icom hex radio codes:

IC-706  	0x4e
IC-706MKIIG 	0x58
IC-725		0x28
IC-726		0x30
IC-735		0x04
IC-746		0x66
IC-751		0x1c
IC-756PRO	0x5c
IC-756PROII	0x64
IC-761		0x1e
IC-765		0x2c	
IC-775  	0x46
IC-781		0x26
IC-970		0x2e
IC-7000 	0x70
IC-R71		0x1A
IC-R72		0x32
IC-R75		0x5a
IC-R7000 	0x08
IC-R7100 	0x34
IC-R8500 	0x4a
IC-R9000 	0x2a

=end

      @radio_info_hash = {
         "IC-706-Boat" => [0x4e,["ham_hf","marine_hf","marine_vhf_short","E"]],
         "IC-706-Home" => [0x4e,["ham_hf","marine_hf","vhf_repeaters_short","E"]],
         "IC-746" => [0x56,["ham_hf","marine_hf","marine_vhf_short","vhf_repeaters_short","E"]],
         "IC-756" => [0x5c,["ham_hf","marine_hf","E"]],
         "IC-R8500" => [0x4a,["ham_hf","marine_hf","cb","marine_vhf_long","vhf_repeaters_long","E"]]
      }

      @radio_serial = nil

      @modeNames = [
         "lsb",
         "usb",
         "am",
         "cw",
         "rtty",
         "fm",
         "wfm"
      ]

      # create a hash of mode names and numbers
      @modes = {}
      i = 0
      @modeNames.each do |s|
         @modes[s] = i
         i += 1
      end
      @radio_name = ""
      @mem_bank = -1
      @mem_loc = -1

      # hook the exit routine
      at_exit { do_at_exit() }
   end # initialize

   def do_at_exit()
      @radio_serial.close if @radio_serial
   end # do_at_exit

   def setup()
      unless @radio_serial # unless already set up
         unless FileTest.exist? @ser_port
            puts "Error: input port #{@ser_port} doesn't exist, quitting."
            exit 0
         end

         # configure the serial port
         `#{@ser_config}`

         # now open it for reading and writing
         @radio_serial = File.open(@ser_port,"rb+")
      end
   end

   def debug_print(s)
      print s if DEBUG
   end

   def read_radio(n)
      debug_print "Read radio: "
      count = 0
      reply = []
      begin
         c = @radio_serial.sysread(1)[0]
         reply << c
         debug_print sprintf("%02x ",c)
         count += 1
      end while count < n
      debug_print "\n"
      return reply
   end # read_radio

   def write_radio(com)
      debug_print "Write radio: "
      com.each do |b| # send the com a byte at a time
         debug_print sprintf("%02x ",b)
         @radio_serial.syswrite b.chr()
      end
      debug_print "\n"
      read_radio(com.length) # absorb the radio's echo
   end #write_radio

   def read_response()
      reply = read_radio(6)
      return reply[4] == 0xfb # meaning no errors
   end # read_response

   def convert_bcd(n,count)
      bcd_array = []
      1.upto(count) do
         bcd_array << ((n % 10) | ((n/10) % 10) << 4)
         n /= 100
      end
      return bcd_array
   end # convert_bcd

   # send a formatted command to a particular radio
   def send_com(c,data = nil)
      com = [ 0xfe,0xfe,@radio_hex_id,0xe0 ]
      com << c
      if(data)
         data.each do |b|
            com << b
         end
      end
      com << 0xfd
      write_radio(com)
      unless read_response()
         err = "Error: "
         com.each do |b|
            err += sprintf("%02x ",b)
         end
         err += "\n"
         debug_print err
      end # response error printing block
   end # send_com

   # just to give it a name
   def set_memory_mode()
      send_com(0x08)
   end

   def set_vfo(n)
      if(@current_vfo != n)
         @current_vfo = n
         send_com(0x07) # select VFO mode (required for IC-756)
         send_com(0x07,[ 0xd0 + n ]) # select VFO main/sub (required for IC-756)
         send_com(0x07,[ n ]) # select VFO
      end
   end # set_vfo

   def set_split(state)
      @split = state
      send_com(0x0f,[ @split?1:0 ]) # split off
   end # set_split

   # "set_memory_bank" is only needed for receivers IC-R8500 and IC-7000.

   def set_memory_bank(mb)
      if(mb != @mem_bank)
         bcd = convert_bcd(mb,1)
         send_com(0x08,bcd.reverse.unshift(0xA0))
         @mem_bank = mb
      end
   end # set_memory_bank

   def set_memory_addr(m)
      if @radio_name =~ /(IC-R8500|IC-R7000)/
         mi = (m.to_i)
         ma = mi % 40
         mb = mi / 40
         set_memory_bank(mb)
         bcd = convert_bcd(ma,2)
      else
         bcd = convert_bcd((m.to_i)+1,2)
      end
      send_com(0x08,bcd.reverse)
      print "." # user feedback
      $stdout.flush # user feedback
   end # set_memory_addr

   def set_vfo_freq(n)
      n = (n.to_f * 1e6) + 0.5
      n = n.to_i
      bcd = convert_bcd(n,5)
      send_com(0x05,bcd)
   end # set_vfo_freq

   def set_vfo_tone(n,f)
      f = (f.to_f * 10) + 0.5
      f = f.to_i
      bcd = convert_bcd(f,2)
      bcd = bcd.reverse
      bcd.unshift n
      send_com(0x1b,bcd)
   end # set_vfo_tone

   def set_vfo_mode(s)
      s = s.gsub(/"/,"")
      send_com(0x06,[ @modes[s] ])
   end # set_vfo_mode

   def get_field_by_name(name_hash,fields,name)
      r = nil
      if(name_hash.has_key?(name))
         n = name_hash[name]
         if(n < fields.size && fields[n].length > 0)
            r = fields[n]
         end
      end
      return r
   end # get_field_by_name

   def process_file(file)
      debug_print file + "\n"
      if (file == "E") # erase unused locations
         set_memory_mode()
         mod = 100 # for most radios
         mod = 40  if @radio_name =~ /(IC-R8500|IC-R7000)/

         while(@mem_loc == 0 || @mem_loc % mod != 0)
            set_memory_addr(@mem_loc)
            send_com(0x0b)
            @mem_loc += 1
         end

      else # normal data file
         data = File.read(@data_directory + "/" + file + ".csv")
         data.gsub!(%r{"},"") # remove all quotes

         records = data.split("\n")

         header = records.shift # get header line

         # create hash to translate field names into numbers
         name_hash = {}
         n = 0
         header.split(",").each do |name|
            if(name && name.length > 0)
               name_hash[name] = n
            end
            n += 1
         end

         @current_vfo = -1
         set_split(false)

         records.each do |record|
            fields = record.split(",")

            # these don't all have to be defined in each table

            mode = get_field_by_name(name_hash,fields,"Mode")
            rxf = get_field_by_name(name_hash,fields,"RxFreq")
            txf = get_field_by_name(name_hash,fields,"TxFreq")
            rxt = get_field_by_name(name_hash,fields,"RxTone")
            txt = get_field_by_name(name_hash,fields,"TxTone")

            if(rxf && mode) # minimum required information
               set_memory_addr(@mem_loc)
               if(txf) # if transmit frequency specified
                  set_split(true) unless @split
                  set_vfo(1)
                  set_vfo_freq(txf)
                  set_vfo_mode(mode)
                  if(txt) # transmit repeater tone
                     send_com(0x16,[ 0x42,0x1 ]) # repeater tone on
                     set_vfo_tone(0,txt)
                  else
                     send_com(0x16,[ 0x42,0x0 ]) # repeater tone off
                  end
               else
                  set_split(false) if @split
               end
               set_vfo(0)
               set_vfo_freq(rxf)
               set_vfo_mode(mode)
               if(rxt) # receiver tone squelch
                  send_com(0x16,[ 0x43,0x1 ]) # tone squelch on
                  set_vfo_tone(1,rxt)
               else
                  send_com(0x16,[ 0x43,0x0 ]) # tone squelch off
               end
               send_com(0x09) # write mem
               @mem_loc += 1
            end # defined rxf and mode
         end # record
      end # normal file read
   end # process_file

   def program_radio(radio_name)

      unless @radio_info_hash.has_key?(radio_name)
         puts "Error: don't recognize radio name \"#{radio_name}\", stopping."
         return
      end
      print "Programming #{radio_name} "
      @radio_name = radio_name
      @radio_info = @radio_info_hash[radio_name]

      @radio_hex_id = @radio_info[0]
      file_list = @radio_info[1]
      @mem_loc = 0
      file_list.each do |fn|
         process_file(fn)
      end

      # go to memory location 0 on exit
      set_memory_addr(0)
      puts "" # user feedback
   end # program_radio

   # "generate_lists" creates master CSV data files for each radio,
   # with memory locations, as programmed by IcomProgrammer.
   # This is not as easy as it might sound --
   # different tables for the same radio are allowed
   # to have different field names and positions.

   # /add/remove/change order of/ field names in this list to suit your needs

   FIELD_NAMES = [ "Bank","Mem","Name","Mode","RxFreq",
      "TxFreq","RxTone","TxTone","Comment",
      "Place","Call","Sponsor","Region"
   ]

   def generate_lists()
      data_path = "radio_lists"
      Dir.mkdir(data_path) unless FileTest.exists?(data_path)
      @radio_info_hash.keys.sort.each do |key|
         # create a hash of field names to numbers
         header_hash = {}
         used_hash = {}
         n = 0
         FIELD_NAMES.each do |fieldname|
            header_hash[fieldname] = n
            used_hash[fieldname] = false
            n += 1
         end
         banked_mem_radio = (key =~ /(IC-R8500|IC-R7000)/)
         field_hash = {} # for global scope
         table = []
         table << FIELD_NAMES # add header to table
         mem_loc = 0
         bank_num = 0
         bmem_num = 0
         @radio_info_hash[key][1].each do |file|
            unless (file == "E")
               data = File.read(@data_directory + "/" + file + ".csv")
               data.gsub!(%r{"},"") # strip all quotes
               recn = 0
               data.split("\n").each do |record|
                  if(banked_mem_radio)
                     mi = (mem_loc.to_i)
                     bmem_num = mi % 40
                     bank_num = mi / 40
                  end
                  fields = record.split(",")
                  if(recn == 0) # header
                     n = 0
                     field_hash = {}
                     fields.each do |fieldname|
                        field_hash[fieldname] = n
                        n += 1
                     end
                  else # a data record
                     rec_arr = []
                     FIELD_NAMES.each do |name|
                        case name
                        when "Bank"
                           if(banked_mem_radio)
                              rec_arr << "#{bank_num}"
                              used_hash[name] = true
                           else
                              rec_arr << ""
                           end
                        when "Mem"
                           if(banked_mem_radio)
                              rec_arr << "#{bmem_num}"
                           else
                              rec_arr << "#{mem_loc+1}"
                           end
                           used_hash[name] = true
                        else
                           if(field_hash.has_key?(name))
                              item = fields[field_hash[name]]
                              if(item)
                                 rec_arr << item
                                 used_hash[name] = true
                              else
                                 rec_arr << ""
                              end
                           else
                              rec_arr << ""
                           end
                        end
                     end # each header name
                     table << rec_arr
                     mem_loc += 1
                  end # header/record
                  recn += 1
               end # each record
            end # unless filename == "E"
         end # each file in file list
         # now open and write data file
         fn = data_path + "/" + key.gsub(/\s/,"_") + ".csv"
         f = File.open(fn,"w")
         table.each do |record|
            outrec = []
            n = 0
            # only add fields that were used
            FIELD_NAMES.each do |fieldname|
               if(used_hash[fieldname])
                  outrec << record[n]
               end
               n += 1
            end # each field
            f.write "\"" + outrec.join("\",\"") + "\"\n"
         end # each record
         f.close
         puts "Created data file #{fn}."
      end # each radio
   end # generate lists

   def process_list(list)
      list.each do |radio_name|
         if(radio_name == "-g")
            generate_lists()
         else
            setup()
            program_radio(radio_name)
         end
      end
   end # process list

   def process(args)
      # if one or more radio names are
      # specified on the command line
      if(args[0])
         # process command-line radio names
         process_list(args)
      else # show a menu of choices
         begin
            puts "Choose an action:"
            menu_list = []
            @radio_info_hash.keys.sort.each do |key|
               menu_list << "Program " + key
            end
            menu_list << "Generate Memory Lists"
            menu_list << "Quit"
            index = 1
            menu_list.each do |name|
               puts "   #{index}) #{name}"
               index += 1
            end
            print "Choose (1 - #{index-1}):"
            line = readline.chomp
            if(line =~ /\d+/)
               choice = (line.to_i)-1
               if(choice >= 0 && choice < index)
                  option = menu_list[choice]
                  case option
                  when "Quit" # no action
                  when "Generate Memory Lists"
                     generate_lists()
                  else # program a radio
                     process_list([option.sub(/Program /,"")])
                  end
               end
            end
         end while option != "Quit"
      end
   end # process args

end # class IcomProgrammer

ip = IcomProgrammer.new
ip.process(ARGV)