require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "valid with known name" do
    role = Role.new(name: "producer")
    assert role.valid?
  end

  test "invalid with unknown name" do
    role = Role.new(name: "superhero")
    assert_not role.valid?
    assert_includes role.errors[:name], "is not included in the list"
  end

  test "name must be unique" do
    Role.create!(name: "writer")
    duplicate = Role.new(name: "writer")
    assert_not duplicate.valid?
  end
end
