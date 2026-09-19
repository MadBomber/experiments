# frozen_string_literal: true

# Compatibility shims for sqa 0.0.38 against modern polars-df (0.27) and
# the current Alpha Vantage free tier. Require AFTER 'sqa'.
#
# These belong upstream in the sqa gem; remove this file once sqa is
# updated. Each shim covers one breakage:
#
#   1. Polars.read_csv dtypes:      -> schema_overrides: (+ symbol dtypes)
#   2. Polars::Series#apply         -> #map_elements
#   3. Polars::DataFrame#with_column -> #with_columns
#   4. Polars::DataFrame#sort reverse: -> descending:
#   5. Alpha Vantage outputsize=full is premium-only now -> force compact

# 1. read_csv keyword rename, plus :f64 / :i64 symbols -> dtype classes
module PolarsDtypesCompat
  SYMBOL_DTYPES = {
    f32: Polars::Float32, f64: Polars::Float64,
    i8: Polars::Int8, i16: Polars::Int16, i32: Polars::Int32, i64: Polars::Int64,
    u8: Polars::UInt8, u16: Polars::UInt16, u32: Polars::UInt32, u64: Polars::UInt64,
    str: Polars::String, bool: Polars::Boolean, date: Polars::Date
  }.freeze

  def read_csv(source, **options)
    if (dtypes = options.delete(:dtypes))
      options[:schema_overrides] ||= dtypes.transform_values { |t| SYMBOL_DTYPES.fetch(t, t) }
    end
    super(source, **options)
  end
end
Polars.singleton_class.prepend(PolarsDtypesCompat)

# 2. Series#apply was renamed to #map_elements
unless Polars::Series.method_defined?(:apply)
  Polars::Series.class_eval { alias_method :apply, :map_elements }
end

# 3. DataFrame#with_column was folded into #with_columns
unless Polars::DataFrame.method_defined?(:with_column)
  Polars::DataFrame.class_eval { alias_method :with_column, :with_columns }
end

# 4. DataFrame#sort renamed reverse: to descending:
module PolarsSortReverseCompat
  def sort(by, *more_by, **options)
    options[:descending] = options.delete(:reverse) if options.key?(:reverse)
    super
  end
end
Polars::DataFrame.prepend(PolarsSortReverseCompat)

# 5. Alpha Vantage made outputsize=full premium-only; SQA::Stock hardcodes
#    full: true and then chokes on the JSON notice that comes back. Force
#    compact fetches (last 100 trading days).
module AlphaVantageCompactOnly
  def recent(ticker, full: false, from_date: nil)
    super(ticker, full: false, from_date: from_date)
  end
end
SQA::DataFrame::AlphaVantage.singleton_class.prepend(AlphaVantageCompactOnly)
