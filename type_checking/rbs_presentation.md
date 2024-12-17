# RBS: Ruby Signature Language Overview

https://www.youtube.com/watch?v=GOC4BRJ-OPY

## Introduction to RBS

RBS is a language used to describe the types in Ruby programs. Introduced in Ruby 3.0, RBS aims to support better code analysis, aid in understanding legacy code, and provide more robust tooling for Ruby developers.

### Objectives of RBS

- **Enhanced Code Quality**: By introducing type definitions, RBS contributes to reducing the number of bugs in Ruby applications.
- **Improved Tooling**: Tools and IDEs can leverage RBS for better code completion, error detection, and documentation.
- **Code Analysis**: With explicit type information, analyzing code for performance and scalability becomes more actionable.
- **Better Documentation**: RBS can also serve as a form of documentation, representing the contract that methods or classes adhere to.

## RBS Key Features

1. **Type Definitions for Ruby**: Define types for variables, method arguments, and return values.
2. **Generics and Type Variables**: Support for generics and type variables, enabling more precise type declarations.
3. **Interface and Duck Typing Support**: Define interfaces (abstract classes) and support for Ruby's duck typing.
4. **Standard Library Signatures**: Bundled signatures for Ruby's standard library, enhancing the effectiveness of using RBS in typical Ruby projects.

## RBS Syntax and Examples

RBS syntax is straightforward and designed to be readable and writable by developers. Here's a quick look at some basic constructs:

### Class and Module Definition

```rbs
class User
  attr_reader name: String
  attr_reader age: Integer
  def initialize: (String, Integer) -> void
  def greet: () -> String
end
```

### Method Type Definition

```rbs
def greet: () -> String
```

This line defines a `greet` method that takes no arguments and returns a `String`.

### Generics

Using generics, you can define classes or methods that can work with any type:

```rbs
class Array[T]
  def first: () -> T?
end
```

### Union Types

Union types allow a value to be one of several types:

```rbs
def parse(input: String | Pathname): JSON | XML | nil
```

## Working with RBS

### Generating RBS Files

RBS files can be generated manually or with the help of tools like `rbs` gem commands or IDE plugins.

### Type Checking with Steep

[Steep](https://github.com/soutaro/steep) is a gradual typing tool for Ruby, using RBS files to perform its analysis. Integrating Steep in the development workflow enhances the robustness of your Ruby application.

### Integrating with IDEs

Modern IDEs and editors like VSCode, RubyMine, or Vim can be configured to understand RBS, providing enhanced code navigation, auto-completion, and real-time type checking.

## Conclusion

RBS unlocks the potential for safer and more reliable Ruby codebases. By incorporating RBS into their workflow, Ruby developers can enjoy the benefits of static typing while maintaining the language's dynamic nature. As the Ruby community continues to evolve, the adoption of RBS and type checking tools is likely to grow, further enhancing the ecosystem's robustness and developer productivity.

## Resources

- [RBS Official Documentation](https://github.com/ruby/rbs)
- [Ruby 3.0 Release Notes](https://www.ruby-lang.org/en/news/2020/12/25/ruby-3-0-0-released/)
- [Steep: Gradual Typing for Ruby](https://github.com/soutaro/steep)

Whether you're a veteran Rubyist or new to the language, exploring RBS can significantly contribute to improving your projects and workflows.

