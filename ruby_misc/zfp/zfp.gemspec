require_relative "lib/zfp/version"

Gem::Specification.new do |spec|
  spec.name    = "zfp"
  spec.version = Zfp::VERSION
  spec.authors = ["Dewayne VanHoozer"]
  spec.email   = ["dvanhoozer@gmail.com"]

  spec.summary     = "Ruby FFI bindings for the ZFP floating-point compression library"
  spec.description = "Compress and decompress arrays of float/double/int32/int64 in 1-4 " \
                     "dimensions using ZFP's fixed-rate, fixed-precision, fixed-accuracy, " \
                     "or lossless reversible modes. Accepts Ruby Array and Numo::NArray."
  spec.homepage    = "https://github.com/madbomber/zfp"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*", "sig/**/*", "README.md"]

  spec.add_dependency "ffi", "~> 1.0"

  spec.add_development_dependency "numo-narray"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "debug_me"
end
