# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development?

  %w[admin support editor guest].each do |role_name|
    Role.create! name: role_name
  end

  User.create(
    email:                  'guest@example.com',
    password:               'password',
    password_confirmation:  'password'
  ).save

  User.create(
    email:                  'dvanhoozer@gmail.com',
    password:               'password',
    password_confirmation:  'password'
  ).add_role('admin').save

end # if Rails.env.development?
