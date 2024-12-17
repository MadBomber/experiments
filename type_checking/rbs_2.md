Yes, there is a way to auto-generate RBS files for your Ruby classes. While crafting RBS files can be done manually to ensure precise type definitions, for existing large codebases or when you want a quick start, auto-generation can be highly beneficial.

### Using RBS's `rbs prototype rb` Command

Ruby 3.0 and later versions, which include support for RBS, offer a prototype command in the RBS gem that can be used to generate RBS files from Ruby source files. The command `rbs prototype rb` reads Ruby (.rb) files and generates RBS prototype definitions. 

Here's a simple example of how you can use it:

1. First, ensure you have the RBS gem installed:

```sh
gem install rbs
```

2. Use the `rbs prototype rb` command to generate an RBS file for your Ruby class. If you have a file `user.rb`, you can generate an RBS file like this:

```sh
rbs prototype rb user.rb > user.rbs
```

This command reads the `user.rb` source file and writes a prototype definition into `user.rbs`. 

### Tips for Auto-Generated RBS Files

- **Review and Refine**: The generated RBS files serve as a starting point. It's important to review and refine these files to ensure they accurately represent your classes and modules. The auto-generation can't always perfectly infer types, especially for more complex Ruby constructs or dynamic behaviors.
  
- **Iterate**: As your Ruby code evolves, you might need to regenerate and adjust the corresponding RBS files. Incorporate this into your development workflow to maintain type accuracy.

- **Integration with Tools**: Use tools like Steep or other static type checkers that support RBS to validate your Ruby code against the generated RBS files. This helps catch type errors and improves your codebase's robustness.

### Additional Tools

While RBS provides a straightforward way to generate initial type signatures, the community may develop more sophisticated tools and integrations over time. Keeping an eye on Ruby type checking and static analysis developments can help you discover new tools and practices to streamline working with RBS and types in Ruby.

Auto-generating RBS files can save time and provide a foundation for implementing strong static type checking in Ruby projects. However, it's a starting point that benefits significantly from human insight and refinement.

