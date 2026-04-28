# frozen_string_literal: true

require "spec_helper"

LIBZFP_PRESENT = system("pkg-config --exists zfp 2>/dev/null") ||
                 system("brew list zfp > /dev/null 2>&1") ||
                 ["/usr/local/lib", "/opt/homebrew/lib", "/usr/lib"].any? do |dir|
                   Dir.glob("#{dir}/libzfp*").any?
                 end unless defined?(LIBZFP_PRESENT)

RSpec.describe Zfp::Field, skip: !LIBZFP_PRESENT do
  let(:data)   { [1.0, 2.0, 3.0, 4.0] }
  let(:buffer) { Zfp::TypeCoercion.to_buffer(data, :double) }

  describe "1D field" do
    subject(:field) { described_class.new(:double, [4], buffer) }

    it "allocates without error" do
      expect { field }.not_to raise_error
    end

    it "exposes the zfp_type_int" do
      expect(field.zfp_type_int).to eq(Zfp::FFI::ZFP_TYPE_DOUBLE)
    end

    it "exposes the shape" do
      expect(field.shape).to eq([4])
    end

    it "exposes a non-null pointer" do
      expect(field.pointer).not_to be_null
    end

    it "frees without error" do
      expect { field.free }.not_to raise_error
    end
  end

  describe "2D field" do
    it "accepts a 2D shape" do
      buf = Zfp::TypeCoercion.to_buffer([1.0] * 6, :double)
      field = described_class.new(:double, [2, 3], buf)
      expect(field.shape).to eq([2, 3])
      field.free
    end
  end

  describe "4D field" do
    it "accepts a 4D shape" do
      buf = Zfp::TypeCoercion.to_buffer([0.0] * 16, :float)
      field = described_class.new(:float, [2, 2, 2, 2], buf)
      expect(field.shape).to eq([2, 2, 2, 2])
      field.free
    end
  end

  it "raises InvalidShape for 0 dimensions" do
    expect { described_class.new(:double, [], buffer) }.to raise_error(Zfp::InvalidShape)
  end

  it "raises InvalidShape for 5 dimensions" do
    expect { described_class.new(:double, [1, 1, 1, 1, 1], buffer) }.to raise_error(Zfp::InvalidShape)
  end
end
