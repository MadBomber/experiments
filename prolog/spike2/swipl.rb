# frozen_string_literal: true

# Spike 2: SWI-Prolog embedded in Ruby through Fiddle, with callbacks from
# Prolog back into Ruby.
#
#   prolog = Swipl::Engine.instance
#   prolog.consult("parent(alice, bob). parent(bob, dave).")
#   prolog.all('parent(X, Y)')            #=> [{X: :alice, Y: :bob}, {X: :bob, Y: :dave}]
#
#   prolog.function(:shout, 1) { |text| text.upcase }
#   prolog.first('shout("hi", S)')        #=> {S: "HI"}
#
# Nothing to build: Homebrew's SWI-Prolog already ships libswipl.dylib.

require 'fiddle'

module Swipl
  class Error < StandardError; end
  class SyntaxError < Error; end
  class Timeout < Error; end
  class Halted < Error; end

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

  # A variable that was still unbound.
  Var = Data.define(:name) do
    def to_s = name
  end

  # A term with no Ruby equivalent here (dict, rational, blob), kept as text.
  Opaque = Data.define(:text) do
    def to_s = text
  end

  # ------------------------------------------------------------------
  # Where SWI-Prolog lives, asked of the swipl executable itself.
  # ------------------------------------------------------------------
  module Install
    module_function

    # Parses the output of `swipl --dump-runtime-variables`.
    def parse(dump)
      dump.scan(/^(\w+)="([^"]*)";/).to_h
    end

    def variables = @variables ||= parse(`swipl --dump-runtime-variables`)
    def home      = ENV.fetch('SWI_HOME_DIR') { variables.fetch('PLBASE') }

    def library
      ENV.fetch('SWIPL_LIB') { File.join(home, 'lib', variables.fetch('PLARCH'), 'libswipl.dylib') }
    end
  end

  # ------------------------------------------------------------------
  # The C API, as declared in SWI-Prolog.h.
  # ------------------------------------------------------------------
  module Lib
    HANDLE = begin
      Fiddle.dlopen(Install.library)
    rescue Fiddle::DLError => e
      raise LoadError, "cannot load #{Install.library}: #{e.message}"
    end

    PTR  = Fiddle::TYPE_VOIDP
    REF  = Fiddle::TYPE_UINTPTR_T # term_t, atom_t and PL_fid_t are all uintptr_t
    BOOL = Fiddle::TYPE_BOOL
    INT  = Fiddle::TYPE_INT
    UINT = Fiddle::TYPE_UINT
    SIZE = Fiddle::TYPE_SIZE_T
    VOID = Fiddle::TYPE_VOID

    SIGNATURES = {
      PL_initialise:            [[INT, PTR], BOOL],
      PL_thread_self:           [[], INT],
      PL_thread_raise:          [[INT, INT], BOOL],
      PL_register_foreign:      [[PTR, INT, PTR, INT], BOOL],
      PL_predicate:             [[PTR, INT, PTR], PTR],
      PL_open_query:            [[PTR, INT, PTR, REF], PTR],
      PL_next_solution:         [[PTR], INT],
      PL_close_query:           [[PTR], INT],
      PL_exception:             [[PTR], REF],
      PL_raise_exception:       [[REF], BOOL],
      PL_call:                  [[REF, PTR], BOOL],
      PL_open_foreign_frame:    [[], REF],
      PL_discard_foreign_frame: [[REF], VOID],
      PL_new_term_ref:          [[], REF],
      PL_new_term_refs:         [[SIZE], REF],
      PL_copy_term_ref:         [[REF], REF],
      PL_term_type:             [[REF], INT],
      PL_get_nchars:            [[REF, PTR, PTR, UINT], BOOL],
      PL_free:                  [[PTR], VOID],
      PL_get_int64:             [[REF, PTR], BOOL],
      PL_get_float:             [[REF, PTR], BOOL],
      PL_get_list:              [[REF, REF, REF], BOOL],
      PL_get_nil:               [[REF], BOOL],
      PL_get_name_arity:        [[REF, PTR, PTR], BOOL],
      PL_get_arg:               [[INT, REF, REF], BOOL],
      PL_put_atom:              [[REF, REF], BOOL],
      PL_put_chars:             [[REF, INT, SIZE, PTR], BOOL],
      PL_put_term_from_chars:   [[REF, INT, SIZE, PTR], BOOL],
      PL_unify:                 [[REF, REF], BOOL]
    }.freeze

    FUNCTIONS = SIGNATURES.to_h do |name, (args, ret)|
      [name, Fiddle::Function.new(HANDLE[name.to_s], args, ret)]
    end.freeze

    # Term types (PL_term_type).
    VARIABLE, ATOM, INTEGER, RATIONAL, FLOAT, STRING, TERM, NIL, BLOB, LIST_PAIR = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

    # Text conversion flags (PL_get_nchars, PL_put_chars).
    CVT_ATOM    = 0x001
    CVT_STRING  = 0x002
    CVT_INTEGER = 0x008
    CVT_WRITE   = 0x080
    BUF_MALLOC  = 0x0002_0000 # caller owns the text and releases it with PL_free
    REP_UTF8    = 0x0010_0000

    # Query flags and extended results (PL_open_query, PL_next_solution).
    Q_NODEBUG         = 0x04
    Q_CATCH_EXCEPTION = 0x08
    Q_EXT_STATUS      = 0x40
    Q_EXCEPT_HALT     = 0x80
    S_EXCEPTION = -1
    S_FALSE     = 0
    S_TRUE      = 1
    S_LAST      = 2 # succeeded and there are no more solutions

    FA_VARARGS = 0x08 # foreign predicate receives (term_t first, int arity, void *context)

    module_function

    def call(name, *args) = FUNCTIONS.fetch(name).call(*args)

    # A C string that lives for the rest of the process.
    def permanent_string(text)
      pointer = Fiddle::Pointer.malloc(text.bytesize + 1)
      pointer[0, text.bytesize + 1] = "#{text}\0"
      pointer
    end

    # A NULL-terminated char*[] that lives for the rest of the process.
    def permanent_argv(strings)
      argv = Fiddle::Pointer.malloc((strings.size + 1) * Fiddle::SIZEOF_VOIDP)
      strings.each_with_index do |text, i|
        argv[i * Fiddle::SIZEOF_VOIDP, Fiddle::SIZEOF_VOIDP] = [permanent_string(text).to_i].pack('J')
      end
      argv[strings.size * Fiddle::SIZEOF_VOIDP, Fiddle::SIZEOF_VOIDP] = [0].pack('J')
      argv
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
      when Var         then '_'
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
  # Prolog term reference -> Ruby value.
  # ------------------------------------------------------------------
  module Convert
    module_function

    def to_ruby(term)
      case Lib.call(:PL_term_type, term)
      when Lib::VARIABLE  then Var.new(text(term, Lib::CVT_WRITE))
      when Lib::INTEGER   then integer(term)
      when Lib::FLOAT     then float(term)
      when Lib::ATOM      then text(term, Lib::CVT_ATOM).to_sym
      when Lib::STRING    then text(term, Lib::CVT_STRING)
      when Lib::NIL       then []
      when Lib::LIST_PAIR then list(term)
      when Lib::TERM      then compound(term)
      else Opaque.new(text(term, Lib::CVT_WRITE))
      end
    end

    # BUF_MALLOC is essential.  SWI's default text buffers are only released
    # when a foreign predicate returns, and a query driven from Ruby is not
    # inside one: they pile up until SWI aborts with "Too many stacked strings".
    def text(term, flags)
      length  = Fiddle::Pointer.malloc(Fiddle::SIZEOF_SIZE_T, Fiddle::RUBY_FREE)
      address = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP, Fiddle::RUBY_FREE)
      ok = Lib.call(:PL_get_nchars, term, length, address, flags | Lib::REP_UTF8 | Lib::BUF_MALLOC)
      raise Error, 'cannot read term text' unless ok

      buffer = address.ptr
      text = buffer.to_s(length[0, Fiddle::SIZEOF_SIZE_T].unpack1('J')).force_encoding(Encoding::UTF_8)
      Lib.call(:PL_free, buffer)
      text
    end

    def integer(term)
      slot = Fiddle::Pointer.malloc(8, Fiddle::RUBY_FREE)
      return slot[0, 8].unpack1('q') if Lib.call(:PL_get_int64, term, slot)

      text(term, Lib::CVT_INTEGER).to_i # too big for 64 bits
    end

    def float(term)
      slot = Fiddle::Pointer.malloc(8, Fiddle::RUBY_FREE)
      Lib.call(:PL_get_float, term, slot)
      slot[0, 8].unpack1('d')
    end

    def list(term)
      tail = Lib.call(:PL_copy_term_ref, term)
      head = Lib.call(:PL_new_term_ref)
      items = []
      items << to_ruby(head) while Lib.call(:PL_get_list, tail, head, tail)
      return items if Lib.call(:PL_get_nil, tail)

      # A partial list such as [a|T] stays a chain of '[|]' terms.
      items.reverse.reduce(to_ruby(tail)) { |rest, item| Term.new(:'[|]', [item, rest]) }
    end

    def compound(term)
      name  = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP, Fiddle::RUBY_FREE)
      arity = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT, Fiddle::RUBY_FREE)
      Lib.call(:PL_get_name_arity, term, name, arity)

      functor = Lib.call(:PL_new_term_ref)
      Lib.call(:PL_put_atom, functor, name[0, Fiddle::SIZEOF_VOIDP].unpack1('J'))
      Term.new(text(functor, Lib::CVT_ATOM).to_sym, arguments(term, arity[0, Fiddle::SIZEOF_INT].unpack1('i')))
    end

    def arguments(term, arity)
      (1..arity).map do |index|
        argument = Lib.call(:PL_new_term_ref)
        Lib.call(:PL_get_arg, index, term, argument)
        to_ruby(argument)
      end
    end

    # Ruby value -> a fresh term reference, by parsing its quoted text.
    def to_term(value)
      text = Quote.term(value)
      term = Lib.call(:PL_new_term_ref)
      ok = Lib.call(:PL_put_term_from_chars, term, Lib::REP_UTF8, text.bytesize, text)
      raise Error, "SWI-Prolog cannot parse #{text}" unless ok

      term
    end
  end

  # ------------------------------------------------------------------
  # The one SWI-Prolog engine in this process.
  #
  # libswipl holds a single global Prolog, bound to the thread that started
  # it, so this is a singleton and refuses calls from other threads.
  # ------------------------------------------------------------------
  class Engine
    QUERY_FLAGS = Lib::Q_NODEBUG | Lib::Q_CATCH_EXCEPTION | Lib::Q_EXT_STATUS | Lib::Q_EXCEPT_HALT
    TIMEOUT_SIGNAL = Signal.list.fetch('USR2')

    # Helper predicates the Ruby side relies on.
    BOOTSTRAP = [
      # Parse a goal from text, keeping its variable names, and run it.
      "assertz(('$ruby_query'(Text, Bindings) :-
          term_string(Goal, Text, [variable_names(Bindings)]),
          call(Goal)))",
      # Load clauses from a string as if it were a file called Name.
      "assertz(('$ruby_consult'(Name, Source) :-
          setup_call_cleanup(open_string(Source, In),
                             load_files(Name, [stream(In)]),
                             close(In))))",
      # A Ruby watchdog thread raises this signal to stop a runaway query.
      "assertz(('$ruby_timeout'(_Signal) :- throw(ruby_timeout)))",
      "on_signal(usr2, _, '$ruby_timeout')"
    ].freeze

    def self.instance = @instance ||= new

    private_class_method :new

    # Query text for a goal, with Ruby values bound to named variables first.
    def self.goal_text(goal, bind = {})
      body = goal.strip.sub(/\.\z/, '')
      bindings = bind.map { |name, value| "#{Quote.variable(name)} = #{Quote.term(value)}" }
      [*bindings, "(#{body})"].join(', ')
    end

    def initialize
      arguments = ['swipl', "--home=#{Install.home}", '--quiet', '--signals=false']
      raise Error, 'PL_initialise failed' unless Lib.call(:PL_initialise, arguments.size, Lib.permanent_argv(arguments))

      @thread = Thread.current
      @prolog_thread = Lib.call(:PL_thread_self)
      @closures = {}      # keeps callback closures alive; SWI holds raw pointers to them
      @ruby_errors = {}   # exceptions raised in callbacks, waiting to resurface
      @depth = 0
      @consults = 0
      BOOTSTRAP.each { |clause| run_bootstrap(clause) }
      @query_predicate = Lib.call(:PL_predicate, '$ruby_query', 2, 'user')
    end

    # Load clauses from a string of Prolog source.  Consulting the same
    # name again replaces what that name defined before.
    def consult(source, name: nil)
      name ||= "ruby_source_#{@consults += 1}"
      first("'$ruby_consult'(Name, Source)", bind: { Name: name.to_sym, Source: source })
      self
    end

    # Yields each solution as a Hash of variable name => Ruby value.
    # Without a block, returns an Enumerator.
    #
    #   bind:    { Name: value } binds variables to Ruby values safely.
    #   timeout: seconds allowed for finding each solution.
    def query(goal, bind: {}, timeout: nil)
      return enum_for(:query, goal, bind:, timeout:) unless block_given?

      check_thread
      text = self.class.goal_text(goal, bind)
      frame = Lib.call(:PL_open_foreign_frame)
      arguments = Lib.call(:PL_new_term_refs, 2)
      Lib.call(:PL_put_chars, arguments, Lib::STRING | Lib::REP_UTF8, text.bytesize, text)
      query = Lib.call(:PL_open_query, nil, QUERY_FLAGS, @query_predicate, arguments)
      @depth += 1
      begin
        loop do
          status = with_timeout(timeout) { Lib.call(:PL_next_solution, query) }
          raise translate(Lib.call(:PL_exception, query), goal) if status == Lib::S_EXCEPTION
          break if status == Lib::S_FALSE

          yield solution(arguments + 1)
          break if status == Lib::S_LAST
        end
      ensure
        Lib.call(:PL_close_query, query)
        Lib.call(:PL_discard_foreign_frame, frame)
        @depth -= 1
        @ruby_errors.clear if @depth.zero?
      end
      self
    end

    def first(goal, **) = query(goal, **).first
    def all(goal, **)   = query(goal, **).to_a
    def true?(goal, **) = !first(goal, **).nil?

    # --- callbacks: Prolog calling Ruby -----------------------------------

    # name/arity succeeds when the block returns a truthy value.
    #
    #   prolog.predicate(:weekend, 1) { |day| %i[sat sun].include?(day) }
    def predicate(name, arity, &block)
      foreign(name, arity) { |first_argument| !!block.call(*ruby_arguments(first_argument, arity)) }
    end

    # name/(arity + 1): the block's return value is unified with the last
    # argument.
    #
    #   prolog.function(:shout, 1) { |text| text.upcase }   # shout("hi", S)
    def function(name, arity, &block)
      foreign(name, arity + 1) do |first_argument|
        result = block.call(*ruby_arguments(first_argument, arity))
        Lib.call(:PL_unify, first_argument + arity, Convert.to_term(result))
      end
    end

    # name/arity backed by a Ruby collection: the block returns rows (Arrays
    # of arity values) and Prolog backtracks over the ones that unify.
    # Unbound arguments arrive as Swipl::Var.
    #
    #   prolog.relation(:employee, 2) { |_name, _dept| Employee.pluck(:name, :dept) }
    def relation(name, arity, &block)
      rows = :"$ruby_rows_#{name}"
      function(rows, arity, &block)
      variables = (1..arity).map { |i| "A#{i}" }.join(', ')
      head = Quote.atom(name)
      first("assertz((#{head}(#{variables}) :- #{Quote.atom(rows)}(#{variables}, Rows), member([#{variables}], Rows)))")
      self
    end

    private

    def check_thread
      raise Error, 'SWI-Prolog must be called from the thread that started it' unless Thread.current == @thread
    end

    def run_bootstrap(clause)
      frame = Lib.call(:PL_open_foreign_frame)
      term = Lib.call(:PL_new_term_ref)
      ok = Lib.call(:PL_put_term_from_chars, term, Lib::REP_UTF8, clause.bytesize, clause) &&
           Lib.call(:PL_call, term, nil)
      Lib.call(:PL_discard_foreign_frame, frame)
      raise Error, "bootstrap failed: #{clause}" unless ok
    end

    # Bindings arrive as a list of 'Name' = Value terms.
    def solution(bindings)
      frame = Lib.call(:PL_open_foreign_frame)
      pairs = Convert.to_ruby(bindings)
      Lib.call(:PL_discard_foreign_frame, frame)
      pairs.to_h { |pair| pair.args }.reject { |name, _| name.start_with?('_') }
    end

    # Turns the exception term of a failed query into a Ruby exception.
    def translate(exception, goal)
      term = Convert.to_ruby(exception)
      case term
      in Term[functor: :ruby_error, args: [id, *]] if @ruby_errors.key?(id)
        @ruby_errors.delete(id)
      in :ruby_timeout
        Timeout.new("timed out: #{goal}")
      in Term[functor: :unwind, args: [Term[functor: :halt, args: [status]]]]
        Halted.new("Prolog called halt(#{status})")
      in Term[functor: :error, args: [Term[functor: :syntax_error], *]]
        SyntaxError.new("cannot parse: #{goal}")
      else
        PrologError.new(term)
      end
    end

    # Fiddle releases the GVL during a call, so a Ruby thread can signal the
    # Prolog thread while PL_next_solution is running.
    def with_timeout(seconds)
      return yield unless seconds

      state = { running: true }
      lock = Mutex.new
      timer = Thread.new do
        sleep seconds
        lock.synchronize { Lib.call(:PL_thread_raise, @prolog_thread, TIMEOUT_SIGNAL) if state[:running] }
      end
      begin
        yield
      ensure
        lock.synchronize { state[:running] = false }
        timer.kill
      end
    end

    def ruby_arguments(first_argument, arity)
      (0...arity).map { |offset| Convert.to_ruby(first_argument + offset) }
    end

    # Registers a C-callable closure as the foreign predicate name/arity.
    # The block gets the first argument's term reference and returns true
    # or false.
    #
    # A Ruby exception must never unwind through SWI-Prolog's C frames, so
    # it is caught here and re-raised inside Prolog as ruby_error(Id, ...).
    # If no Prolog code catches it, #query raises the original exception.
    def foreign(name, arity, &body)
      closure = Fiddle::Closure::BlockCaller.new(Lib::REF, [Lib::REF, Lib::INT, Lib::PTR]) do |first_argument, _arity, _context|
        body.call(first_argument) ? 1 : 0
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise_in_prolog(e)
        0
      end
      @closures[[name, arity]] = closure
      ok = Lib.call(:PL_register_foreign, Lib.permanent_string(name.to_s), arity, closure, Lib::FA_VARARGS)
      raise Error, "cannot register #{name}/#{arity}" unless ok

      self
    end

    def raise_in_prolog(exception)
      id = exception.object_id
      @ruby_errors[id] = exception
      term = Convert.to_term(Term.new(:ruby_error, [id, exception.class.name.to_sym, exception.message]))
      Lib.call(:PL_raise_exception, term)
    end
  end
end
