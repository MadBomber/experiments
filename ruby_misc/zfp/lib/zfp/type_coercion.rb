# frozen_string_literal: true

module Zfp
  module TypeCoercion
    RUBY_TO_ZFP_TYPE = {
      int32:  Zfp::FFI::ZFP_TYPE_INT32,
      int64:  Zfp::FFI::ZFP_TYPE_INT64,
      float:  Zfp::FFI::ZFP_TYPE_FLOAT,
      double: Zfp::FFI::ZFP_TYPE_DOUBLE
    }.freeze

    PACK_FORMAT = {
      float:  "e*",
      double: "E*",
      int32:  "l<*",
      int64:  "q<*"
    }.freeze

    ELEMENT_SIZE = {
      float:  4,
      double: 8,
      int32:  4,
      int64:  8
    }.freeze

    class << self
      def detect_type(data)
        return nil unless numo?(data)
        case data
        when Numo::SFloat then :float
        when Numo::DFloat then :double
        when Numo::Int32  then :int32
        when Numo::Int64  then :int64
        else raise Zfp::InvalidType, "Unsupported Numo type: #{data.class}"
        end
      end

      def detect_shape(data)
        return nil unless numo?(data)
        data.shape
      end

      def numo?(data)
        defined?(Numo::NArray) && data.is_a?(Numo::NArray)
      end

      def to_buffer(data, type)
        numo?(data) ? numo_to_buffer(data, type) : array_to_buffer(data, type)
      end

      def from_buffer(ptr, type, shape, as_numo)
        as_numo ? buffer_to_numo(ptr, type, shape) : buffer_to_array(ptr, type, shape)
      end

      private

      def array_to_buffer(array, type)
        fmt = PACK_FORMAT.fetch(type) { raise Zfp::InvalidType, "Unknown type: #{type}" }
        packed = array.flatten.pack(fmt)
        ptr = ::FFI::MemoryPointer.new(:uint8, packed.bytesize)
        ptr.put_bytes(0, packed)
        ptr
      end

      def numo_to_buffer(narray, type)
        fmt = PACK_FORMAT.fetch(type) { raise Zfp::InvalidType, "Unknown type: #{type}" }
        packed = narray.to_a.flatten.pack(fmt)
        ptr = ::FFI::MemoryPointer.new(:uint8, packed.bytesize)
        ptr.put_bytes(0, packed)
        ptr
      end

      def buffer_to_array(ptr, type, shape)
        count = shape.reduce(:*)
        bytes = ptr.read_bytes(count * ELEMENT_SIZE[type])
        bytes.unpack(PACK_FORMAT[type])
      end

      def buffer_to_numo(ptr, type, shape)
        count = shape.reduce(:*)
        bytes = ptr.read_bytes(count * ELEMENT_SIZE[type])
        array = bytes.unpack(PACK_FORMAT[type])
        numo_class_for(type).cast(array).reshape(*shape)
      end

      def numo_class_for(type)
        case type
        when :float  then Numo::SFloat
        when :double then Numo::DFloat
        when :int32  then Numo::Int32
        when :int64  then Numo::Int64
        else raise Zfp::InvalidType, "Unknown type: #{type}"
        end
      end
    end
  end
end
