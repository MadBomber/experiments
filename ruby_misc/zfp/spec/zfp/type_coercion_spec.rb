require "spec_helper"
require "numo/narray"

RSpec.describe Zfp::TypeCoercion do
  describe ".detect_type" do
    it "returns nil for Ruby Array" do
      expect(described_class.detect_type([1.0, 2.0])).to be_nil
    end

    it "returns :float for Numo::SFloat" do
      expect(described_class.detect_type(Numo::SFloat[1.0, 2.0])).to eq(:float)
    end

    it "returns :double for Numo::DFloat" do
      expect(described_class.detect_type(Numo::DFloat[1.0, 2.0])).to eq(:double)
    end

    it "returns :int32 for Numo::Int32" do
      expect(described_class.detect_type(Numo::Int32[1, 2])).to eq(:int32)
    end

    it "returns :int64 for Numo::Int64" do
      expect(described_class.detect_type(Numo::Int64[1, 2])).to eq(:int64)
    end
  end

  describe ".detect_shape" do
    it "returns nil for Ruby Array" do
      expect(described_class.detect_shape([1.0, 2.0])).to be_nil
    end

    it "returns shape array for Numo::NArray" do
      na = Numo::DFloat.new(3, 4).fill(0)
      expect(described_class.detect_shape(na)).to eq([3, 4])
    end
  end

  describe ".numo?" do
    it "returns false for Ruby Array" do
      expect(described_class.numo?([1.0])).to be false
    end

    it "returns true for Numo::NArray" do
      expect(described_class.numo?(Numo::DFloat[1.0])).to be true
    end
  end

  describe "round-trip via to_buffer / from_buffer" do
    {
      float:  [1.5, 2.5, 3.5, 4.5],
      double: [1.5, 2.5, 3.5, 4.5],
      int32:  [1, 2, 3, 4],
      int64:  [1, 2, 3, 4]
    }.each do |type, data|
      context "Ruby Array of #{type}" do
        it "round-trips correctly" do
          ptr = described_class.to_buffer(data, type)
          result = described_class.from_buffer(ptr, type, [4], false)
          data.zip(result).each { |a, b| expect(b).to be_within(0.001).of(a) }
        end
      end
    end

    context "Numo::DFloat" do
      it "round-trips correctly" do
        na = Numo::DFloat[1.5, 2.5, 3.5]
        ptr = described_class.to_buffer(na, :double)
        result = described_class.from_buffer(ptr, :double, [3], true)
        expect(result).to be_a(Numo::DFloat)
        expect(result.to_a).to eq([1.5, 2.5, 3.5])
      end
    end

    context "Numo::SFloat" do
      it "round-trips correctly" do
        na = Numo::SFloat[1.0, 2.0]
        ptr = described_class.to_buffer(na, :float)
        result = described_class.from_buffer(ptr, :float, [2], true)
        expect(result).to be_a(Numo::SFloat)
      end
    end
  end
end
