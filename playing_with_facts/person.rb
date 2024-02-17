# experiments/prolog/person.rb

class Person
  attr_reader :id, :name, :sex, :age

  def initialize(id, name, sex, age)
    @id   = id
    @name = name
    @sex  = sex
    @age  = age
  end


  def to_s
    @name
  end
end
