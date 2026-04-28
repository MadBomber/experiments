# frozen_string_literal: true

require "spec_helper"

LIBZFP_PRESENT = system("pkg-config --exists zfp 2>/dev/null") ||
                 system("brew list zfp > /dev/null 2>&1") ||
                 ["/usr/local/lib", "/opt/homebrew/lib", "/usr/lib"].any? do |dir|
                   Dir.glob("#{dir}/libzfp*").any?
                 end

RSpec.describe Zfp::FFI, skip: !LIBZFP_PRESENT do
  it "loads the zfp library" do
    expect(described_class).to be_a(Module)
  end

  %i[
    zfp_stream_open zfp_stream_close zfp_stream_set_bit_stream zfp_stream_rewind
    zfp_stream_set_rate zfp_stream_set_precision zfp_stream_set_accuracy
    zfp_stream_set_reversible zfp_stream_maximum_size
    zfp_compress zfp_decompress
    zfp_field_alloc zfp_field_free zfp_field_set_pointer zfp_field_set_type
    zfp_field_set_size_1d zfp_field_set_size_2d zfp_field_set_size_3d zfp_field_set_size_4d
    stream_open stream_close
  ].each do |fn|
    it "attaches #{fn}" do
      expect(described_class).to respond_to(fn)
    end
  end
end
