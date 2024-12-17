Absolutely, incorporating Ruby Signatures (RBS) and Sorbet into your Ruby guild meeting presents an excellent opportunity to delve into adding stronger type checking to Ruby code, an area of growing interest and importance in the Ruby community. Below, I'll provide a brief example for both RBS and Sorbet to help kickstart your presentation planning.

### 1. RBS Example

RBS is part of the Ruby language from version 3.0, aimed at describing the types of Ruby programs. You can write signatures for your standard Ruby code, allowing for better type checking.

First, you'll need an RBS file for your class. Suppose you have a simple `User` class. You could start with creating a file named `user.rbs` to define its type signature.

**File: user.rbs**

```rbs
class User
  attr_accessor name: String
  attr_accessor age: Integer
  def initialize: (String, Integer) -> void
  def greeting: () -> String
end
```

This file defines a `User` class with a constructor that takes a `String` and an `Integer`, two accessors for `name` and `age`, and a `greeting` method that returns a `String`.

**File: user.rb**

```ruby
class User
  attr_accessor :name, :age

  def initialize(name, age)
    @name, @age = name, age
  end

  def greeting
    "Hello, #{@name}!"
  end
end
```

To check the type definitions, you'll then use the RBS CLI, after ensuring you have the RBS gem installed. You could run a type check like this:

```shell
rbs validate user.rb
```

### 2. Sorbet Example

Sorbet is a static type checker for Ruby, allowing for gradual typing. First, install Sorbet in your project:

```shell
gem install sorbet
# Initialize Sorbet in your project
srb init
```

After initializing Sorbet, let's use the same `User` class example with type annotations.

**File: user.rb**

```ruby
# typed: true
class User
  extend T::Sig

  sig {params(name: String, age: Integer).void}
  def initialize(name, age)
    @name = name
    @age = age
  end

  sig {returns(String)}
  def greeting
    "Hello, #{@name}!"
  end

  # Define accessors with types
  sig {returns(String)}
  attr_reader :name

  sig {returns(Integer)}
  attr_reader :age
end
```

To run type checks with Sorbet, you'd use:

```shell
srb tc
```

This command checks your Ruby files against their type signatures defined in-line using Sorbet's syntax.

### Presentation Tips:

- Start with the basics of type checking and why it's important in Ruby, setting the context.
- Introduce RBS and Sorbet separately, covering their installation, basic usage, and benefits.
- Provide examples similar to the ones above but also consider more complex scenarios that might be typical in your guild members' work.
- Discuss limitations and considerations when adopting type checking in a Ruby project.
- Encourage live coding or interactive sessions where members can attempt to add types to existing Ruby code.
- If possible, share real-world use cases from renowned projects or experiences within the guild.

This framework should offer a comprehensive and engaging presentation that will not only introduce RBS and Sorbet to your guild members but also demonstrate their practical application in making Ruby code more reliable and maintainable.

