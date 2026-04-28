require "spec_helper"

RSpec.describe Zfp::Packer do
  let(:raw_bytes) { "compressed_data_stub" }

  ROUND_TRIP_CASES = [
    { type: :float,  shape: [100],        mode: :reversible,      params: {},                 numo: false },
    { type: :double, shape: [10, 20],     mode: :fixed_rate,      params: { rate: 4.0 },      numo: false },
    { type: :int32,  shape: [5, 5, 5],    mode: :fixed_precision, params: { precision: 16 },  numo: false },
    { type: :int64,  shape: [2, 2, 2, 2], mode: :fixed_accuracy,  params: { tolerance: 0.001 }, numo: true  }
  ].freeze

  ROUND_TRIP_CASES.each do |c|
    it "round-trips #{c[:type]} #{c[:mode]} #{c[:shape].inspect}" do
      packed = described_class.encode(raw_bytes, **c)
      type, shape, mode, params, numo, data = described_class.decode(packed)
      expect(type).to  eq(c[:type])
      expect(shape).to eq(c[:shape])
      expect(mode).to  eq(c[:mode])
      expect(numo).to  eq(c[:numo])
      expect(data).to  eq(raw_bytes)
    end
  end

  it "encodes the rate param for fixed_rate" do
    packed = described_class.encode(raw_bytes, type: :double, shape: [10], mode: :fixed_rate,
                                    params: { rate: 8.0 }, numo: false)
    _, _, _, params, = described_class.decode(packed)
    expect(params[:rate]).to be_within(0.001).of(8.0)
  end

  it "encodes the precision param for fixed_precision" do
    packed = described_class.encode(raw_bytes, type: :double, shape: [10], mode: :fixed_precision,
                                    params: { precision: 20 }, numo: false)
    _, _, _, params, = described_class.decode(packed)
    expect(params[:precision]).to eq(20)
  end

  it "encodes the tolerance param for fixed_accuracy" do
    packed = described_class.encode(raw_bytes, type: :double, shape: [10], mode: :fixed_accuracy,
                                    params: { tolerance: 1e-5 }, numo: false)
    _, _, _, params, = described_class.decode(packed)
    expect(params[:tolerance]).to be_within(1e-10).of(1e-5)
  end

  it "raises PackerError for wrong magic" do
    bad = "BAAD" + "\x00" * 28 + raw_bytes
    expect { described_class.decode(bad) }.to raise_error(Zfp::PackerError, /magic/)
  end

  it "raises PackerError for truncated header" do
    expect { described_class.decode("ZFP\x01\x00") }.to raise_error(Zfp::PackerError, /truncated/)
  end
end
