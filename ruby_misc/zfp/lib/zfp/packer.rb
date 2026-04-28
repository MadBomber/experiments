# frozen_string_literal: true

module Zfp
  module Packer
    MAGIC      = "ZFP\x01"
    HEADER_LEN = 32
    PACK_FMT   = "a4CCCCVVVVE"

    TYPE_TO_BYTE = { float: 0, double: 1, int32: 2, int64: 3 }.freeze
    BYTE_TO_TYPE = TYPE_TO_BYTE.invert.freeze

    MODE_TO_BYTE = { fixed_rate: 0, fixed_precision: 1, fixed_accuracy: 2, reversible: 3 }.freeze
    BYTE_TO_MODE = MODE_TO_BYTE.invert.freeze

    def self.encode(compressed_bytes, type:, shape:, mode:, params: {}, numo: false)
      flags  = numo ? 1 : 0
      dims   = shape.length
      dim0, dim1, dim2, dim3 = Array.new(4) { |i| shape[i].to_i }
      param  = extract_param(mode, params)
      header = [MAGIC, TYPE_TO_BYTE[type], MODE_TO_BYTE[mode], dims, flags,
                dim0, dim1, dim2, dim3, param].pack(PACK_FMT)
      header + compressed_bytes
    end

    def self.decode(bytes)
      if bytes.bytesize < HEADER_LEN
        raise Zfp::PackerError, "truncated header (#{bytes.bytesize} < #{HEADER_LEN} bytes)"
      end

      magic, type_b, mode_b, rank, flags, d0, d1, d2, d3, param =
        bytes[0, HEADER_LEN].unpack(PACK_FMT)

      raise Zfp::PackerError, "bad magic bytes (expected ZFP\\x01)" unless magic == MAGIC

      type  = BYTE_TO_TYPE.fetch(type_b) { raise Zfp::PackerError, "unknown type byte #{type_b}" }
      mode  = BYTE_TO_MODE.fetch(mode_b) { raise Zfp::PackerError, "unknown mode byte #{mode_b}" }
      shape = [d0, d1, d2, d3].first(rank)
      numo  = flags & 1 == 1
      params = decode_params(mode, param)
      data  = bytes[HEADER_LEN..]

      [type, shape, mode, params, numo, data]
    end

    private_class_method def self.extract_param(mode, params)
      case mode
      when :fixed_rate      then params[:rate].to_f
      when :fixed_precision then params[:precision].to_f
      when :fixed_accuracy  then params[:tolerance].to_f
      else 0.0
      end
    end

    private_class_method def self.decode_params(mode, param)
      case mode
      when :fixed_rate      then { rate: param }
      when :fixed_precision then { precision: param.round }
      when :fixed_accuracy  then { tolerance: param }
      else {}
      end
    end
  end
end
