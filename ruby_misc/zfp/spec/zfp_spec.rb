require "spec_helper"
require "numo/narray"

unless defined?(LIBZFP_PRESENT)
  LIBZFP_PRESENT = system("pkg-config --exists zfp 2>/dev/null") ||
                   system("brew list zfp > /dev/null 2>&1") ||
                   ["/usr/local/lib", "/opt/homebrew/lib", "/usr/lib"].any? do |dir|
                     Dir.glob("#{dir}/libzfp*").any?
                   end
end

RSpec.describe Zfp, skip: !LIBZFP_PRESENT do
  let(:data)  { (1..20).map(&:to_f) }
  let(:shape) { [20] }

  describe ".compress / .decompress" do
    context "with Ruby Array" do
      it "compresses to a non-empty String" do
        bytes = Zfp.compress(data, type: :double, shape: shape, mode: :reversible)
        expect(bytes).to be_a(String)
        expect(bytes.bytesize).to be > 0
      end

      it "round-trips exactly via reversible mode" do
        bytes  = Zfp.compress(data, type: :double, shape: shape, mode: :reversible)
        result = Zfp.decompress(bytes, type: :double, shape: shape, mode: :reversible)
        expect(result).to eq(data)
      end

      it "returns Numo when numo: true" do
        bytes  = Zfp.compress(data, type: :double, shape: shape, mode: :reversible)
        result = Zfp.decompress(bytes, type: :double, shape: shape, mode: :reversible, numo: true)
        expect(result).to be_a(Numo::DFloat)
      end
    end

    context "with Numo::DFloat (type and shape inferred)" do
      let(:na) { Numo::DFloat.cast(data) }

      it "infers type and shape from Numo::NArray" do
        bytes = Zfp.compress(na, mode: :reversible)
        expect(bytes).to be_a(String)
      end
    end
  end

  describe ".pack / .unpack" do
    it "round-trips a Ruby Array" do
      packed = Zfp.pack(data, type: :double, shape: shape, mode: :reversible)
      result = Zfp.unpack(packed)
      expect(result).to eq(data)
    end

    it "round-trips a Numo::DFloat and returns Numo::DFloat" do
      na     = Numo::DFloat.cast(data)
      packed = Zfp.pack(na, mode: :reversible)
      result = Zfp.unpack(packed)
      expect(result).to be_a(Numo::DFloat)
      expect(result.to_a).to eq(data)
    end

    it "raises PackerError on malformed input" do
      expect { Zfp.unpack("not a valid packed buffer") }.to raise_error(Zfp::PackerError)
    end
  end
end
