# frozen_string_literal: true

class PageFinder < HighVoltage::PageFinder
  def find
    paths = super.split('/')
    directory = paths[0..-2]
    filename = paths[-1].tr('-', '_')

    File.join(*directory, filename)
  end
end
