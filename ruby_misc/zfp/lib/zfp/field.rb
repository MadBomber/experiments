# frozen_string_literal: true

module Zfp
  class Field
    attr_reader :zfp_type_int, :shape

    def initialize(type, shape, buffer)
      validate_shape!(shape)
      @type         = type
      @shape        = shape
      @buffer       = buffer  # hold reference — prevents GC while field is alive
      @zfp_type_int = Zfp::TypeCoercion::RUBY_TO_ZFP_TYPE[type]
      @ptr = Zfp::FFI.zfp_field_alloc
      raise Zfp::Error, "Failed to allocate zfp_field" if @ptr.null?

      Zfp::FFI.zfp_field_set_pointer(@ptr, buffer)
      Zfp::FFI.zfp_field_set_type(@ptr, @zfp_type_int)
      set_shape(shape)
    end

    def pointer
      @ptr
    end

    def dims
      @shape.length
    end

    def free
      return if @ptr.nil? || @ptr.null?
      Zfp::FFI.zfp_field_free(@ptr)
      @ptr = ::FFI::Pointer::NULL
    end

    private

    def validate_shape!(shape)
      unless shape.is_a?(Array) && shape.length.between?(1, 4) &&
             shape.all? { |d| d.is_a?(Integer) && d > 0 }
        raise Zfp::InvalidShape,
          "shape must be an Array of 1–4 positive integers, got #{shape.inspect}"
      end
    end

    def set_shape(shape)
      case shape.length
      when 1 then Zfp::FFI.zfp_field_set_size_1d(@ptr, shape[0])
      when 2 then Zfp::FFI.zfp_field_set_size_2d(@ptr, shape[0], shape[1])
      when 3 then Zfp::FFI.zfp_field_set_size_3d(@ptr, shape[0], shape[1], shape[2])
      when 4 then Zfp::FFI.zfp_field_set_size_4d(@ptr, shape[0], shape[1], shape[2], shape[3])
      end
    end
  end
end
