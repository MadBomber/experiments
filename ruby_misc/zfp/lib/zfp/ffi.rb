# frozen_string_literal: true

require "ffi"

module Zfp
  module FFI
    extend ::FFI::Library

    begin
      ffi_lib "zfp"
    rescue LoadError
      raise Zfp::LibraryNotFound,
        "ZFP library not found. Install with: brew install zfp"
    end

    ZFP_TYPE_INT32  = 1
    ZFP_TYPE_INT64  = 2
    ZFP_TYPE_FLOAT  = 3
    ZFP_TYPE_DOUBLE = 4

    attach_function :zfp_stream_open,           [:pointer],                                          :pointer
    attach_function :zfp_stream_close,          [:pointer],                                          :void
    attach_function :zfp_stream_set_bit_stream, [:pointer, :pointer],                                :void
    attach_function :zfp_stream_rewind,         [:pointer],                                          :void
    attach_function :zfp_stream_set_rate,       [:pointer, :double, :int, :uint, :int],              :double
    attach_function :zfp_stream_set_precision,  [:pointer, :uint],                                   :uint
    attach_function :zfp_stream_set_accuracy,   [:pointer, :double],                                 :double
    attach_function :zfp_stream_set_reversible, [:pointer],                                          :void
    attach_function :zfp_stream_maximum_size,   [:pointer, :pointer],                                :size_t
    attach_function :zfp_compress,              [:pointer, :pointer],                                :size_t
    attach_function :zfp_decompress,            [:pointer, :pointer],                                :size_t

    attach_function :zfp_field_alloc,           [],                                                  :pointer
    attach_function :zfp_field_free,            [:pointer],                                          :void
    attach_function :zfp_field_set_pointer,     [:pointer, :pointer],                                :void
    attach_function :zfp_field_set_type,        [:pointer, :int],                                    :void
    attach_function :zfp_field_set_size_1d,     [:pointer, :size_t],                                 :void
    attach_function :zfp_field_set_size_2d,     [:pointer, :size_t, :size_t],                        :void
    attach_function :zfp_field_set_size_3d,     [:pointer, :size_t, :size_t, :size_t],               :void
    attach_function :zfp_field_set_size_4d,     [:pointer, :size_t, :size_t, :size_t, :size_t],      :void

    attach_function :stream_open,               [:pointer, :size_t],                                 :pointer
    attach_function :stream_close,              [:pointer],                                          :void
  end
end
