require 'hashie'

class AIA::Tools
  # Class array to keep track of subclasses and their metadata
  @@catalog = []

  class << self
    # Triggered when a subclass is created
    def inherited(subclass)
      subclass_meta = Hashie::Mash.new(klass: subclass)
      subclass.instance_variable_set(:@_metadata, subclass_meta)

      # Add the subclass and its metadata to the catalog as a Hash
      @@catalog << subclass_meta
    end

    # Instance method for setting or updating metadata
    def meta(metadata = nil)
      # On retrieval, return the current metadata
      return @_metadata if metadata.nil?

      # On setting, update the _metadata
      @_metadata = Hashie::Mash.new(metadata)

      # Update the entry in the catalog
      entry = @@catalog.detect { |item| item[:klass] == self }
      entry.merge!(metadata) if entry
    end

    def get_meta
      @_metadata
    end

    # Class method to search for subclasses matching certain criteria
    def search_for(criteria = {})
      @@catalog.select do |meta|
        criteria.all? { |k, v| meta[k] == v }
      end
    end

    # Exposes the contents of the entire catalog
    def catalog
      @@catalog
    end

    # Method to load subclasses from a tools directory
    def load_subclasses
      Dir.glob(File.join(File.dirname(__FILE__), 'tools', '*.rb')).each do |file|
        require file
      end
    end
  end
end


