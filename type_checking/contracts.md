The `contracts` gem in Ruby is a powerful tool for enforcing contracts (agreements about the behavior of your code) between pieces of your program at runtime. Unlike static type checkers like RBS or Sorbet, which provide their benefits at the development phase before code execution, the `contracts` gem works by checking that method inputs and outputs adhere to specified contracts during execution. This approach can be a valuable defense against type mismatch problems and other unexpected behaviors, ensuring your methods are used correctly.

### Getting Started with Contracts

1. **Installation**

First, add the gem to your project's Gemfile and run `bundle install`, or install it directly using RubyGems:

```sh
gem install contracts
```

2. **Basic Usage**

To use `contracts`, you include the `Contracts` module in your classes or modules and then define contracts for your methods using the provided syntax. Here's a simple example:

```ruby
require 'contracts'
include Contracts

Contract Num, Num => Num
def add(a, b)
  a + b
end
```

In this case, `Contract Num, Num => Num` specifies that the `add` method takes two numerical arguments and returns a numerical value. If the method is called with arguments that do not satisfy these conditions, or if it returns a non-numerical value, the `contracts` gem will raise a `ContractError` at runtime.

### Advanced Contracts

The `contracts` gem supports a wide range of contract types, allowing you to specify contracts more precisely:

- **Basic Types**: You can use basic Ruby classes, such as `String`, `Numeric`, or any user-defined class.
- **Array and Hash**: It supports specifying the types of elements in arrays or hashes, e.g., `ArrayOf[String]` or `HashOf[Symbol => Num]`.
- **Custom Contracts**: You can define your custom contracts for more complex scenarios, leveraging lambda expressions or dedicated classes.

### Example

Here's a more complex example showing several capabilities of the `contracts` gem:

```ruby
require 'contracts'
include Contracts

class User
  include Contracts::Core
  include Contracts::Builtin

  Contract String, Num => Any
  def initialize(name, age)
    @name = name
    @age = age
  end

  Contract None => String
  def introduce
    "Hello, my name is #{@name} and I am #{@age} years old."
  end
end

user = User.new("Alice", 30)
puts user.introduce
```

This example specifies that `User#initialize` takes a `String` and a `Num` and that `User#introduce` takes no arguments (`None`) and returns a `String`.

### Benefits and Considerations

- **Runtime Safety**: By ensuring methods are called with the correct types and return the expected types, you can catch and handle errors more gracefully.
- **Documentation**: Contracts act as a form of living documentation, making it clear what a method expects and returns.
- **Flexibility**: The ability to define custom contracts allows for sophisticated type checks that can adjust to very specific needs.

However, it's essential to consider that runtime checks may introduce performance overhead and are fundamentally different from static type checks, which can catch issues earlier in the development process. Using the `contracts` gem effectively requires careful thought about where and how to apply contracts to balance safety, performance, and maintainability.

In summary, the `contracts` gem offers a robust mechanism for adding runtime type checks and other contract-based validations to Ruby applications, complementing traditional testing and static analysis tools.

