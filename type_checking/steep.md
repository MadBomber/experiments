Steep is a static type checker for Ruby, utilizing RBS (Ruby Signature) files to perform its analysis. Developed by Soutaro Matsumoto and other contributors, Steep brings static typing benefits to Ruby, enabling developers to detect type mismatches and other potential issues early in the development process. By leveraging RBS, Steep allows for detailed and precise type specifications that go beyond what's possible with traditional documentation or informal type comments.

### Getting Started with Steep

To use Steep, you first need to ensure you have Ruby and the RBS gem installed, as Steep is built upon RBS for its type definitions.

1. **Install Steep**:

To install Steep, run:

```sh
gem install steep
```

2. **Initialize Steep**:

In your Ruby project directory, initialize Steep:

```sh
steep init
```

This command creates a `Steepfile` in your project, which configures how Steep operates, including which directories to check.

3. **Write or Generate RBS Files**:

You need RBS files for the Ruby classes and modules you want to check. You can write these by hand, focusing on critical areas, or generate prototypes using `rbs prototype rb` as described in a previous answer.

Suppose you have a simple `user.rb` file:

```ruby
class User
  attr_reader :name, :age

  def initialize(name:, age:)
    @name, name
    @age, age
  end

  def greeting
    "Hello, #{@name}"
  end
end
```

You could create or generate an RBS file, `user.rbs`, for it:

```rbs
class User
  attr_reader name: String
  attr_reader age: Integer
  def initialize: (name: String, age: Integer) -> void
  def greeting: () -> String
end
```

4. **Configure Steep**:

Edit the `Steepfile` to include the paths to your Ruby and RBS files:

```ruby
target :app do
  signature "sig"

  check "lib"
end
```

This configuration tells Steep to use RBS files located in the `sig` directory and to check Ruby files in the `lib` directory.

5. **Run Steep to Perform Type Checking**:

With your RBS files in place and Steep configured, run:

```sh
steep check
```

Steep will analyze the Ruby files against the provided RBS signatures, reporting any type mismatches or issues it finds.

### Understanding Steep's Output

When Steep finds type inconsistencies or other problems, it reports them in a readable format pointing to the specific file and line number. For example:

```
user.rb:5:4: [error] Type `(::String | ::Integer)` cannot be assigned to type `::String`
```

This output means there's a type mismatch on line 5 of `user.rb`, where something that could be either a String or an Integer is being assigned to a variable or returned from a method that is expected to only be a String, according to the RBS files.

### Wrap Up

Steep, combined with RBS, offers a powerful way to introduce static type checking into Ruby applications. By specifying detailed type information in RBS files and using Steep to analyze your code, you can catch bugs early, improve code quality, and enjoy a more robust development experience in Ruby. As with any tool, integrating Steep into your workflow will require some setup and learning, but the benefits it brings in terms of code quality and maintainability can be significant.

