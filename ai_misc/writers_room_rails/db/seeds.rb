# Create the 5 roles
Role::NAMES.each { |name| Role.find_or_create_by!(name:) }

# Create initial producer user
producer_role = Role.find_by!(name: "producer")
producer = User.find_or_create_by!(email: "dvanhoozer@gmail.com") do |u|
  u.name = "Dewayne VanHoozer"
end
producer.roles << producer_role unless producer.has_role?(:producer)

puts "Seeded #{Role.count} roles"
puts "Seeded producer user: #{producer.email}"
