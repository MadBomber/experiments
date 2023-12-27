require 'hashie'

class AIA::Tools
  # Class variable to keep track of subclasses and their metadata
  @@catalog = Hashie::Mash.new

  class << self

    # Triggered when a subclass is created
    def inherited(subclass)
      key = subclass.name.split('::').last.downcase

      # Create metadata with the class name
      subclass_meta = Hashie::Mash.new(klass: subclass )
      
      subclass.instance_variable_set(:@_metadata, subclass_meta)
      
      # Add the subclass and its metadata to the catalog
      # Use the class name as the key
      @@catalog[key] = subclass_meta
    end


    # Clas    # Instance method for setting or updating metadata
    def meta(metadata = nil)
      # On retrieval, return the current metadata
      return @_metadata if metadata.nil?
      
      # On setting, update the _metadata and the entry in the catalog
      @_metadata = Hashie::Mash.new(metadata)
      
      key = self.name.split('::').last.downcase
      @@catalog[key].merge! metadata
    end

    def get_meta
      @_metadata
    end

    # Class method to search for subclasses matching certain criteria
    def search_for(criteria = {})
      @@catalog.select do |name, meta|
        criteria.all? do |k, v|
          meta[k] == v
        end
      end # .map(&:values)
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
