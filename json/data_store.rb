# experiments/json/data_store.rb

require 'forwardable'
require 'oj'

=begin

  ReportData::DataStore is intended to allow either an internal Array or
  and external file to be used as the data array for reports.  The reason
  that an external file is used is to reduce the amount of memory used in
  the sidekiq process that creates the different report renderings.

=end


module ReportData
  class DataStore
    extend  Forwardable

    # keeps count of the number of JSON objects writen to the scratch file
    attr_accessor :size

    def initialize(filename=nil)
      if filename.nil?
        setup_array_store
      else
        setup_file_store(filename)
      end
    end


    def setup_array_store
      @file = nil
      @data = Array.new

      self.class.def_delegators(
        :@data,
        :<<, :each, :[], :blank?, :empty?, :nil?, :size
      )
    end


    # Store the data array in a text file where each line in the file
    # is a JSON object.  The file store is treated like a tape.  It is
    # not randomly accessable.  You write to it, close it, then read it
    # back.
    def setup_file_store(filename)
      @filename = filename
      @file     = File.open(@filename, 'w')
      @size     = 0

      # self.class.def_delegators :@file, :close
    end


    def close
      @file.close unless @file.nil?
    end


    def <<(an_entry)
      @file.puts Oj.dump(an_entry)
      @size += 1
    end


    def size
      @size
    end


    def empty?
      0 == @size
    end
    alias_method :blank?, :empty?


    # Rewind the tape and sequentally provide each saved entry
    def each
      raise "RequiresBlock" unless block_given?

      close
      @file = File.open(@filename, 'r')

      while !@file.eof? do
        yield Oj.load(@file.gets)
      end
    end
  end # class DataStore
end # module ReportData
