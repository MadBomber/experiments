# frozen_string_literal: true

# A spike: Trealla Prolog embedded in Ruby through Fiddle.
#
#   engine = Trealla::Engine.new
#   engine.consult("parent(alice, bob). parent(bob, dave).")
#   engine.query('parent(X, Y)').to_a   #=> [{X: :alice, Y: :bob}, {X: :bob, Y: :dave}]
#   engine.first('parent(P, Kid)', bind: { Kid: :dave })   #=> {Kid: :dave, P: :bob}
#
# Run `ruby build.rb` first to produce build/libtrealla.dylib.

require 'fiddle'
require 'monitor'

module Trealla
  class Error < StandardError; end
  class SyntaxError < Error; end
  class Timeout < Error; end

  # An error raised by Prolog code.  #term is the error term as Ruby data.
  class PrologError < Error
    attr_reader :term

    def initialize(term)
      @term = term
      super(term.to_s)
    end
  end

  # A compound term such as f(a, B) that is not a list.
  Term = Data.define(:functor, :args) do
    def to_s = Quote.term(self)
  end

  # A variable that was still unbound in the answer.
  Var = Data.define(:name) do
    def to_s = name
  end

  # ------------------------------------------------------------------
  # The C API, as declared in trealla.h.
  # ------------------------------------------------------------------
  module Lib
    PATH = ENV.fetch('TREALLA_LIB', File.expand_path('build/libtrealla.dylib', __dir__))

    HANDLE = begin
      Fiddle.dlopen(PATH)
    rescue Fiddle::DLError => e
      raise LoadError, "cannot load #{PATH} (#{e.message}); run `ruby build.rb` first"
    end

    PTR    = Fiddle::TYPE_VOIDP
    BOOL   = Fiddle::TYPE_BOOL
    INT    = Fiddle::TYPE_INT
    UINT   = Fiddle::TYPE_UINT
    SIZE_T = Fiddle::TYPE_SIZE_T
    VOID   = Fiddle::TYPE_VOID

    SIGNATURES = {
      pl_create:        [[], PTR],
      pl_destroy:       [[PTR], VOID],
      pl_consult_text:  [[PTR, PTR, SIZE_T, PTR], BOOL],
      pl_query:         [[PTR, PTR, PTR, UINT], BOOL],
      pl_redo:          [[PTR], BOOL],
      pl_done:          [[PTR], BOOL],
      pl_free:          [[PTR], VOID],
      pl_num_bindings:  [[PTR], UINT],
      pl_binding_name:  [[PTR, UINT], PTR],
      pl_binding_value: [[PTR, UINT], PTR],
      pl_term_type:     [[PTR], INT],
      pl_atom_text:     [[PTR], PTR],
      pl_atom_len:      [[PTR], SIZE_T],
      pl_get_int64:     [[PTR, PTR], BOOL],
      pl_get_float:     [[PTR, PTR], BOOL],
      pl_term_text:     [[PTR], PTR],
      pl_int_text:      [[PTR, INT], PTR],
      pl_functor:       [[PTR], PTR],
      pl_arity:         [[PTR], UINT],
      pl_arg:           [[PTR, UINT], PTR],
      get_status:       [[PTR], BOOL],
      get_halt:         [[PTR], BOOL],
      set_dump_vars:    [[PTR, INT], VOID]
    }.freeze

    FUNCTIONS = SIGNATURES.to_h do |name, (args, ret)|
      [name, Fiddle::Function.new(HANDLE[name.to_s], args, ret)]
    end.freeze

    # g_tpl_interrupt is a process-wide int; setting it stops the running query.
    INTERRUPT = Fiddle::Pointer.new(HANDLE['g_tpl_interrupt'])

    module_function

    def call(name, *args) = FUNCTIONS.fetch(name).call(*args)

    def interrupt=(on)
      INTERRUPT[0, Fiddle::SIZEOF_INT] = [on ? 1 : 0].pack('i')
    end

    # Copy a C string that Trealla allocated for us, then release it.
    def take_string(pointer)
      return nil if pointer.null?

      text = pointer.to_s.force_encoding(Encoding::UTF_8)
      call(:pl_free, pointer)
      text
    end
  end

  # ------------------------------------------------------------------
  # Ruby value -> Prolog source text.
  # ------------------------------------------------------------------
  module Quote
    VARIABLE  = /\A[A-Z_][A-Za-z0-9_]*\z/
    BARE_ATOM = /\A[a-z][A-Za-z0-9_]*\z/

    module_function

    def term(value)
      case value
      when Integer     then value.to_s
      when Float       then float(value)
      when Symbol      then atom(value)
      when String      then string(value)
      when Array       then "[#{value.map { |v| term(v) }.join(',')}]"
      when Term        then compound(value)
      when Var         then variable(value.name)
      when true, false then value.to_s
      else raise ArgumentError, "cannot convert #{value.class} to a Prolog term"
      end
    end

    def float(value)
      raise ArgumentError, "#{value} has no Prolog syntax" unless value.finite?

      value.to_s
    end

    # Atoms that need no quotes are written bare, so terms print readably.
    def atom(value)
      name = value.to_s
      name.match?(BARE_ATOM) ? name : "'#{escape(name, "'")}'"
    end

    def string(value) = %("#{escape(value, '"')}")

    def compound(value)
      "#{atom(value.functor)}(#{value.args.map { |arg| term(arg) }.join(',')})"
    end

    def variable(name)
      name = name.to_s
      raise ArgumentError, "#{name.inspect} is not a Prolog variable name" unless name.match?(VARIABLE)

      name
    end

    def escape(text, delimiter)
      text.gsub(/[\\#{delimiter}]/) { |char| "\\#{char}" }.gsub("\n", '\n')
    end
  end

  # ------------------------------------------------------------------
  # Prolog answer term -> Ruby value.
  #
  # A term pointer is only valid until the next pl_redo or pl_done on its
  # query, so everything is copied into Ruby objects straight away.
  # ------------------------------------------------------------------
  module Convert
    VAR, INTEGER, FLOAT, ATOM, STRING, COMPOUND = 0, 1, 2, 3, 4, 5

    module_function

    def to_ruby(term)
      return Var.new('_') if term.null?

      case Lib.call(:pl_term_type, term)
      when VAR      then Var.new(Lib.take_string(Lib.call(:pl_term_text, term)))
      when INTEGER  then integer(term)
      when FLOAT    then float(term)
      when ATOM     then atom(text(term))
      when STRING   then text(term)
      when COMPOUND then compound(term)
      end
    end

    def integer(term)
      slot = Fiddle::Pointer.malloc(8, Fiddle::RUBY_FREE)
      return slot[0, 8].unpack1('q') if Lib.call(:pl_get_int64, term, slot)

      # Too big for 64 bits: read it as hex text.
      Lib.take_string(Lib.call(:pl_int_text, term, 16)).to_i(16)
    end

    def float(term)
      slot = Fiddle::Pointer.malloc(8, Fiddle::RUBY_FREE)
      Lib.call(:pl_get_float, term, slot)
      slot[0, 8].unpack1('d')
    end

    def text(term)
      length = Lib.call(:pl_atom_len, term)
      Lib.call(:pl_atom_text, term).to_s(length).force_encoding(Encoding::UTF_8)
    end

    def atom(name) = name == '[]' ? [] : name.to_sym

    def compound(term)
      functor = Lib.call(:pl_functor, term).to_s
      args = Lib.call(:pl_arity, term).times.map { |i| to_ruby(Lib.call(:pl_arg, term, i)) }
      list(functor, args) || Term.new(functor.to_sym, args)
    end

    # '.'(Head, Tail) with a proper-list tail becomes a Ruby Array.
    def list(functor, args)
      return nil unless functor == '.' && args.size == 2 && args.last.is_a?(Array)

      [args.first, *args.last]
    end
  end

  # ------------------------------------------------------------------
  # Timeouts.  Fiddle releases the GVL during a call, so a Ruby thread can
  # set Trealla's interrupt flag while a query is running.
  # The flag is process-wide: it stops whichever engine is running.
  # ------------------------------------------------------------------
  module Watchdog
    LOCK = Mutex.new

    module_function

    # Runs the block; returns [block_result, timed_out].
    def guard(seconds)
      return [yield, false] unless seconds

      state = { running: true, fired: false }
      timer = Thread.new { sleep seconds; fire(state) }
      result = yield
      [result, state[:fired]]
    ensure
      disarm(state, timer) if state
    end

    def fire(state)
      LOCK.synchronize do
        next unless state[:running]

        state[:fired] = true
        Lib.interrupt = true
      end
    end

    def disarm(state, timer)
      LOCK.synchronize do
        state[:running] = false
        Lib.interrupt = false if state[:fired]
      end
      timer.kill
    end
  end

  # ------------------------------------------------------------------
  # One Prolog engine.  Engines are independent of each other.
  # ------------------------------------------------------------------
  class Engine
    # Every goal is wrapped in catch/3 so a Prolog error arrives as a
    # binding of this variable instead of being printed to stdout.
    ERROR_VARIABLE = 'TreallaRubyError'

    def self.wrap(goal, bind = {})
      body = goal.strip.sub(/\.\z/, '')
      bindings = bind.map { |name, value| "#{Quote.variable(name)} = #{Quote.term(value)}" }
      "catch((#{[*bindings, body].join(', ')}), #{ERROR_VARIABLE}, true)."
    end

    def self.finalizer(pointer) = proc { Lib.call(:pl_destroy, pointer) }

    def initialize
      @pl = Lib.call(:pl_create)
      raise Error, 'pl_create failed' if @pl.null?

      Lib.call(:set_dump_vars, @pl, 0) # do not print answers toplevel-style
      @monitor = Monitor.new
      ObjectSpace.define_finalizer(self, self.class.finalizer(@pl))
    end

    def close
      return if @pl.nil?

      ObjectSpace.undefine_finalizer(self)
      Lib.call(:pl_destroy, @pl)
      @pl = nil
    end

    # Load clauses from a string of Prolog source.
    def consult(source, name: 'ruby')
      ok = @monitor.synchronize { Lib.call(:pl_consult_text, @pl, source, source.bytesize, name) }
      raise Error, "consult of #{name} failed" unless ok

      self
    end

    # Yields each solution as a Hash of variable name => Ruby value.
    # Without a block, returns an Enumerator.
    #
    #   bind:    { Name: value } binds variables to Ruby values safely,
    #            rather than interpolating them into the goal text.
    #   timeout: seconds allowed for finding each solution.
    def query(goal, bind: {}, timeout: nil)
      return enum_for(:query, goal, bind:, timeout:) unless block_given?

      handle = start(self.class.wrap(goal, bind), goal, timeout)
      live = Lib.call(:get_status, @pl)
      begin
        while live
          yield solution(handle)
          live, timed_out = native(timeout) { Lib.call(:pl_redo, handle) }
          handle = nil unless live # a false pl_redo has already freed the query
          raise Timeout, "no further solution within #{timeout}s: #{goal}" if timed_out
        end
      ensure
        @monitor.synchronize { Lib.call(:pl_done, handle) } if handle
      end
      self
    end

    def first(goal, **) = query(goal, **).first
    def all(goal, **)   = query(goal, **).to_a
    def true?(goal, **) = !first(goal, **).nil?

    private

    # Runs a native call under the engine lock, with an optional timeout.
    def native(timeout, &)
      @monitor.synchronize { Watchdog.guard(timeout, &) }
    end

    # Starts a query and returns its handle.
    def start(text, goal, timeout)
      slot = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP, Fiddle::RUBY_FREE)
      slot[0, Fiddle::SIZEOF_VOIDP] = "\0" * Fiddle::SIZEOF_VOIDP
      _, timed_out = native(timeout) { Lib.call(:pl_query, @pl, text, slot, 0) }
      handle = slot.ptr
      raise SyntaxError, "cannot parse: #{goal}" if handle.null?
      return handle unless timed_out

      @monitor.synchronize { Lib.call(:pl_done, handle) }
      raise Timeout, "no solution within #{timeout}s: #{goal}"
    end

    def solution(handle)
      answer = @monitor.synchronize { bindings(handle) }
      error = answer.delete(ERROR_VARIABLE.to_sym)
      raise PrologError, error unless error.nil? || error.is_a?(Var)

      answer
    end

    def bindings(handle)
      Lib.call(:pl_num_bindings, handle).times.to_h do |i|
        name = Lib.call(:pl_binding_name, handle, i).to_s
        [name.to_sym, Convert.to_ruby(Lib.call(:pl_binding_value, handle, i))]
      end
    end
  end
end
