# misc_ruby_snippets/frozen_string_workaround.rb

=begin

  String concatenation is done several ways:
    out = 'chicken' + 'soup'
    out = 'chicken'; out += 'soup'
    out = 'chicken'; out << 'soup'


  The String method breaks when the target object is frozen such as when
  the magic comment "# frozen_string_literal: true" is set or when its
  value is initially frozen like:
    out = 'chicken'.freeze; out << 'soup'

  The reason is that the method << preserves the object.  That is the
  object id before << is the same as the object id after the method call.
  The other methods create new objects which by pass the frozen
  string problem

    out = 'chicken'.freeze
    out << 'soup'  #=> raises an exception
    out += 'soup'  #=> does not becuase out is now a new different object

  Some gems always use the << method for string concat.  The problem
  is how to modify the String class so that the method << is redirected
  to the method += when the target (self) object is frozen.

=end

class String
  alias_method :old_concat,     '<<'.to_sym
  # alias_method :old_plus_eaual, '+='.to_sym # += is not a String method

  def <<(a_string)
    if frozen?
      # old_plus_equal(a_string)  # += is not a String method
      # self += a_string          # can't change balue of self
      unfreeze
      old_concat(a_string)
      freeze
    else
      old_concat(a_string)      # send(:'<<', a_string)
    end
    return self
  end
end

out = 'chicken'
out << 'soup'
puts 'pass-1' if out == 'chickensoup'

begin
  out = 'chicken'.freeze
  puts out
  puts out.object_id
  out << 'shit'
  puts 'pass-2' if out == 'chickenshit'
rescue => e
  puts e
end
puts out
puts out.object_id
