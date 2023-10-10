require 'method_source'

require_relative "method_generator"
require_relative "not_implemented"

# discovered that I can write a simple prompt that
# reviews the entire file looking for the comment labels that match the to-due
# directive.  It takes the text that follows as a requirement and
# writes the ruby code to implement the requirement.

class Calculator
  include MethodGenerator

  def sub(a,b)
    NotImplemented.needs_two "subtract b from a"
  end

  def mult(a, b)
    # TODO: multiplied a by b then divide the result by 2
  end

  def impact(mass, velocity)
    # TODO: return the impact force give the mass and velocity of a moving object.
  end


  def display(a, b, cc, dee)
    # TODO: print the value of each input parameter with the parameters name to STDERR
  end

# TODO: need a new method to take a string as a parameter, evaluate the string and return ifs value..  maybe something like calc "21 / 7"

end

