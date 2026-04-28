# frozen_string_literal: true

require "spec_helper"

unless defined?(LIBZFP_PRESENT)
  LIBZFP_PRESENT = system("pkg-config --exists zfp 2>/dev/null") ||
                   system("brew list zfp > /dev/null 2>&1") ||
                   ["/usr/local/lib", "/opt/homebrew/lib", "/usr/lib"].any? do |dir|
                     Dir.glob("#{dir}/libzfp*").any?
                   end
end

RSpec.describe Zfp::Stream, skip: !LIBZFP_PRESENT do
  let(:data)   { (1..16).map(&:to_f) }
  let(:buffer) { Zfp::TypeCoercion.to_buffer(data, :double) }
  let(:field)  { Zfp::Field.new(:double, [16], buffer) }

  after { field.free }

  describe "reversible mode round-trip" do
    subject(:stream) { described_class.new(:reversible, {}) }

    it "compresses without raising" do
      expect { stream.compress(field) }.not_to raise_error
    end

    it "returns non-empty bytes from compress" do
      bytes = stream.compress(field)
      expect(bytes).to be_a(String)
      expect(bytes.bytesize).to be > 0
    end

    it "round-trips data exactly" do
      compressed = stream.compress(field)

      out_buf = ::FFI::MemoryPointer.new(:uint8, data.length * 8)
      out_field = Zfp::Field.new(:double, [16], out_buf)
      stream.decompress(out_field, compressed)
      result = Zfp::TypeCoercion.from_buffer(out_buf, :double, [16], false)
      out_field.free

      expect(result).to eq(data)
    end
  end

  describe "fixed_rate mode" do
    it "compresses without raising" do
      stream = described_class.new(:fixed_rate, { rate: 4.0 })
      expect { stream.compress(field) }.not_to raise_error
    end
  end
end
