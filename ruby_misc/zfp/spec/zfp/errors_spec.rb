require "spec_helper"

RSpec.describe "Zfp error hierarchy" do
  it "Zfp::Error inherits from StandardError" do
    expect(Zfp::Error.ancestors).to include(StandardError)
  end

  {
    Zfp::LibraryNotFound     => Zfp::Error,
    Zfp::InvalidType         => Zfp::Error,
    Zfp::InvalidMode         => Zfp::Error,
    Zfp::InvalidShape        => Zfp::Error,
    Zfp::InvalidParams       => Zfp::Error,
    Zfp::CompressionFailed   => Zfp::Error,
    Zfp::DecompressionFailed => Zfp::Error,
    Zfp::PackerError         => Zfp::Error
  }.each do |subclass, parent|
    it "#{subclass} < #{parent}" do
      expect(subclass.ancestors).to include(parent)
    end
  end
end
