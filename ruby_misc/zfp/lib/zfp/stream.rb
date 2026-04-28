# frozen_string_literal: true

module Zfp
  class Stream
    def initialize(mode, params)
      @mode   = mode
      @params = params
    end

    def compress(field)
      zfp_ptr = bitstream = output_buf = nil
      zfp_ptr = Zfp::FFI.zfp_stream_open(nil)
      apply_mode(zfp_ptr, field)
      bufsize    = Zfp::FFI.zfp_stream_maximum_size(zfp_ptr, field.pointer)
      output_buf = ::FFI::MemoryPointer.new(:uint8, bufsize)
      bitstream  = Zfp::FFI.stream_open(output_buf, bufsize)
      Zfp::FFI.zfp_stream_set_bit_stream(zfp_ptr, bitstream)
      Zfp::FFI.zfp_stream_rewind(zfp_ptr)
      written = Zfp::FFI.zfp_compress(zfp_ptr, field.pointer)
      raise Zfp::CompressionFailed, "zfp_compress returned 0" if written == 0
      output_buf.read_bytes(written)
    ensure
      Zfp::FFI.stream_close(bitstream) if bitstream && !bitstream.null?
      Zfp::FFI.zfp_stream_close(zfp_ptr) if zfp_ptr && !zfp_ptr.null?
    end

    def decompress(field, compressed_bytes)
      zfp_ptr = bitstream = input_buf = nil
      input_buf = ::FFI::MemoryPointer.new(:uint8, compressed_bytes.bytesize)
      input_buf.put_bytes(0, compressed_bytes)
      zfp_ptr  = Zfp::FFI.zfp_stream_open(nil)
      apply_mode(zfp_ptr, field)
      bitstream = Zfp::FFI.stream_open(input_buf, compressed_bytes.bytesize)
      Zfp::FFI.zfp_stream_set_bit_stream(zfp_ptr, bitstream)
      Zfp::FFI.zfp_stream_rewind(zfp_ptr)
      read = Zfp::FFI.zfp_decompress(zfp_ptr, field.pointer)
      raise Zfp::DecompressionFailed, "zfp_decompress returned 0" if read == 0
    ensure
      Zfp::FFI.stream_close(bitstream) if bitstream && !bitstream.null?
      Zfp::FFI.zfp_stream_close(zfp_ptr) if zfp_ptr && !zfp_ptr.null?
    end

    private

    def apply_mode(zfp_ptr, field)
      case @mode
      when :fixed_rate
        Zfp::FFI.zfp_stream_set_rate(zfp_ptr, @params[:rate].to_f,
                                     field.zfp_type_int, field.dims, 0)
      when :fixed_precision
        Zfp::FFI.zfp_stream_set_precision(zfp_ptr, @params[:precision])
      when :fixed_accuracy
        Zfp::FFI.zfp_stream_set_accuracy(zfp_ptr, @params[:tolerance].to_f)
      when :reversible
        Zfp::FFI.zfp_stream_set_reversible(zfp_ptr)
      end
    end
  end
end
