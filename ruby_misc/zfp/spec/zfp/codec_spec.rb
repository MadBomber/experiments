# frozen_string_literal: true

require "spec_helper"
require "numo/narray"

unless defined?(LIBZFP_PRESENT)
  LIBZFP_PRESENT = system("pkg-config --exists zfp 2>/dev/null") ||
                   system("brew list zfp > /dev/null 2>&1") ||
                   ["/usr/local/lib", "/opt/homebrew/lib", "/usr/lib"].any? do |dir|
                     Dir.glob("#{dir}/libzfp*").any?
                   end
end

RSpec.describe Zfp::Codec, skip: !LIBZFP_PRESENT do
  describe "validation" do
    it "raises InvalidType for unknown type" do
      expect { described_class.new(type: :float128, shape: [10], mode: :reversible) }
        .to raise_error(Zfp::InvalidType)
    end

    it "raises InvalidMode for unknown mode" do
      expect { described_class.new(type: :double, shape: [10], mode: :bogus) }
        .to raise_error(Zfp::InvalidMode)
    end

    it "raises InvalidShape for empty shape" do
      expect { described_class.new(type: :double, shape: [], mode: :reversible) }
        .to raise_error(Zfp::InvalidShape)
    end

    it "raises InvalidShape for 5D shape" do
      expect { described_class.new(type: :double, shape: [1]*5, mode: :reversible) }
        .to raise_error(Zfp::InvalidShape)
    end

    it "raises InvalidParams when fixed_rate missing rate" do
      expect { described_class.new(type: :double, shape: [10], mode: :fixed_rate) }
        .to raise_error(Zfp::InvalidParams)
    end

    it "raises InvalidParams when fixed_precision missing precision" do
      expect { described_class.new(type: :double, shape: [10], mode: :fixed_precision) }
        .to raise_error(Zfp::InvalidParams)
    end

    it "raises InvalidParams when fixed_accuracy missing tolerance" do
      expect { described_class.new(type: :double, shape: [10], mode: :fixed_accuracy) }
        .to raise_error(Zfp::InvalidParams)
    end
  end

  describe "reversible mode (lossless)" do
    %i[float double int32 int64].each do |type|
      context "type=#{type}" do
        let(:data) do
          case type
          when :float, :double then (1..16).map { |i| i * 1.5 }
          when :int32, :int64  then (1..16).to_a
          end
        end

        [[16], [4, 4], [2, 2, 4], [2, 2, 2, 2]].each do |shape|
          context "shape=#{shape.inspect}" do
            let(:codec) { described_class.new(type: type, shape: shape, mode: :reversible) }

            it "compresses to bytes" do
              expect(codec.compress(data)).to be_a(String)
            end

            it "round-trips exactly" do
              result = codec.decompress(codec.compress(data))
              expect(result.length).to eq(data.length)
              data.zip(result).each { |a, b| expect(b).to eq(a) }
            end
          end
        end
      end
    end
  end

  describe "fixed_rate mode" do
    let(:codec) { described_class.new(type: :double, shape: [64], mode: :fixed_rate, rate: 4.0) }
    let(:data)  { Array.new(64) { rand } }

    it "compresses and decompresses within ZFP's rate tolerance" do
      result = codec.decompress(codec.compress(data))
      expect(result.length).to eq(64)
    end
  end

  describe "fixed_accuracy mode" do
    let(:tolerance) { 0.01 }
    let(:codec) do
      described_class.new(type: :double, shape: [100], mode: :fixed_accuracy, tolerance: tolerance)
    end
    let(:data) { Array.new(100) { rand * 100 } }

    it "decompresses within the specified tolerance" do
      result = codec.decompress(codec.compress(data))
      data.zip(result).each do |orig, recon|
        expect((orig - recon).abs).to be <= tolerance * 10
      end
    end
  end

  describe "fixed_precision mode" do
    let(:codec) { described_class.new(type: :double, shape: [50], mode: :fixed_precision, precision: 16) }
    let(:data)  { Array.new(50) { rand * 1000 } }

    it "round-trips within floating-point tolerance" do
      result = codec.decompress(codec.compress(data))
      expect(result.length).to eq(50)
    end
  end

  describe "Numo::NArray input/output" do
    let(:codec) { described_class.new(type: :double, shape: [8], mode: :reversible, numo: true) }
    let(:na)    { Numo::DFloat[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0] }

    it "returns Numo::DFloat from decompress when numo: true" do
      result = codec.decompress(codec.compress(na))
      expect(result).to be_a(Numo::DFloat)
      expect(result.to_a).to eq(na.to_a)
    end
  end

  describe "#pack / Zfp.unpack round-trip" do
    let(:codec) { described_class.new(type: :double, shape: [10], mode: :reversible) }
    let(:data)  { (1..10).map(&:to_f) }

    it "round-trips via pack/unpack" do
      packed = codec.pack(data)
      type, shape, mode, params, numo, compressed = Zfp::Packer.decode(packed)
      result = described_class.new(type: type, shape: shape, mode: mode, **params).decompress(compressed)
      expect(result).to eq(data)
    end
  end
end
