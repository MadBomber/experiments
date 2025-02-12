Ruby's Hidden Gems: Simplifying Programmer's Life

Ruby is renowned for its elegant syntax and developer-friendly features. Among its many treasures, two particularly useful elements stand out:

1. Hash constructor with a block
2. `sort_by` method

Let's dive deeper into these features and see how they can simplify our code.

## Hash Constructor with a Block

The Hash constructor in Ruby allows you to create a hash with a default value using a block. This feature is especially useful when you want to create a hash where each key is associated with a complex default value.

### Example:

```ruby
# Create a hash where each key defaults to an empty array
word_groups = Hash.new { |hash, key| hash[key] = [] }

# Now you can safely append to any key without explicitly initializing it
word_groups['apple'] << 'fruit'
word_groups['carrot'] << 'vegetable'

puts word_groups
# Output: {"apple"=>["fruit"], "carrot"=>["vegetable"]}
```

This approach eliminates the need for explicit key checking and initialization, making your code cleaner and more concise.

## The `sort_by` Method

Ruby's `sort_by` method is a powerful tool for sorting collections based on specific criteria. It's often more readable and efficient than using the standard `sort` method with a comparison block.

### Example:

```ruby
people = [
  { name: 'Alice', age: 30 },
  { name: 'Bob',   age: 25 },
  { name: 'Carol', age: 35 }
]

# Sort people by age
sorted_people = people.sort_by { |person| person[:age] }

puts sorted_people
# Output: [
#   {:name=>"Bob", :age=>25},
#   {:name=>"Alice", :age=>30},
#   {:name=>"Carol", :age=>35}
# ]
```

The `sort_by` method is particularly useful when sorting based on multiple criteria or when dealing with complex objects.

## Practical Application: ETL Process

To illustrate the power of these features, let's look at a practical example involving an ETL (Extract, Transform, Load) process. 

https://github.com/MadBomber/experiments/blob/master/ruby_misc/hash_and_sort_by/etl.rb

