RBS (Ruby Signature) and Sorbet are indeed centered around static type checking. Static type checking is done without running the code. It analyzes the code for type errors, enforcing type constraints at compile-time (or, for interpreted languages like Ruby, before the code is executed). This approach helps catch errors early in the development process, improving code quality and maintainability.

### Static Type Checkers:
- **RBS** is part of Ruby 3.0 and newer versions, providing a way to describe the types of Ruby programs through signature files. These signature files are then used to verify the types of Ruby elements statically, without executing the code.
- **Sorbet**, built by Stripe, is a static type checker for Ruby that can be added to existing projects. It allows developers to gradually type their Ruby codebase using a system of comments and sigils to denote method signatures and variable types.

### Runtime Type Checking:
Unlike static type checking, runtime type checking evaluates the types of expressions as the program runs, offering flexibility and dynamism that can be particularly handy in certain use cases but at the expense of performance and potential runtime errors.

For Ruby, if you're looking for runtime type checking capabilities, you might want to consider the following:

1. **TypeProf**: While primarily a type inference tool that ships with Ruby (from 3.0), TypeProf can also be used to analyze Ruby code for type inconsistencies by running the program and generating RBS prototype signatures. It works at runtime but serves a different primary purpose, facilitating a move towards static type checking by generating RBS files for existing code.

2. **Contracts.ruby**: This gem allows defining contracts (or agreements) for Ruby methods, specifying the expected input types and return types. These contracts are then enforced at runtime, raising an exception if a contract is violated. It enables more robust runtime checks, ensuring that methods receive and return data of the expected types.

   Example with Contracts.ruby:
   ```ruby
   require 'contracts'
   include Contracts
   
   class Example
     Contract Num, Num => Num
     def add(a, b)
       a + b
     end
   end
   
   example = Example.new
   puts example.add(5, 3)  # Works fine
   puts example.add('5', 3)  # Raises a ContractError at runtime
   ```

3. **Runtypes**: Another approach could be using Duck Typing, which is inherently supported by Ruby, or employing libraries like Dry-RB, particularly `dry-types`, to enforce type constraints in a more manual but flexible manner, especially for data validation and casting.

In summary, RBS and Sorbet enhance Ruby's type system through static analysis, contributing to code safety and maintainability. If runtime type checking is necessary, libraries like Contracts.ruby offer a more dynamic approach, providing safeguards against improper type usage as the code executes. These tools and techniques can play complementary roles in making Ruby applications more robust and error-resistant.

