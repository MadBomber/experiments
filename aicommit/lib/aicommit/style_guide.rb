# lib/aicommit_rb/style_guide.rb
module Aicommit
  class StyleGuide
    def self.load(dir)
      style_guide_path = File.join(dir, 'COMMITS.md')
      File.exist?(style_guide_path) ? File.read(style_guide_path) : ''
    end
  end
end
