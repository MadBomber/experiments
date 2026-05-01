# experiments/ruby_misc/playing_with_methods.rb

class X
  def xyzzy = "magic"

  private

  def one
    1
  end

  alias_method :uno, :one
end

# Get the private methods
private_methods = X.private_instance_methods(false)

# Initialize a hash to collect methods and their aliases
aliases = {}

# Check the methods
private_methods.each do |method_name|
  method = X.instance_method(method_name)

  # List of methods currently in the aliases to later compare with
  aliases[method_name] = []

  private_methods.each do |other_method_name|
    next if method_name == other_method_name

    other_method = X.instance_method(other_method_name)

    # Check if they are the same method
    if method == other_method
      aliases[method_name] << other_method_name
    end
  end
end

# Print the aliases
aliases.each do |method_name, alias_methods|
  if alias_methods.any?
    puts "#{method_name} is an alias for: #{alias_methods.join(", ")}"
  end
end
