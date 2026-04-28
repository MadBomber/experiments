# frozen_string_literal: true

module Zfp
  class Error < StandardError; end
  class LibraryNotFound     < Error; end
  class InvalidType         < Error; end
  class InvalidMode         < Error; end
  class InvalidShape        < Error; end
  class InvalidParams       < Error; end
  class CompressionFailed   < Error; end
  class DecompressionFailed < Error; end
  class PackerError         < Error; end
end
