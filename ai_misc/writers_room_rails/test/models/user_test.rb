require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @producer_role = Role.create!(name: "producer")
    @writer_role   = Role.create!(name: "writer")
    @user = User.create!(email: "test@example.com", name: "Test User")
  end

  test "requires email" do
    user = User.new(name: "No Email")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "email must be unique" do
    duplicate = User.new(email: "test@example.com", name: "Duplicate")
    assert_not duplicate.valid?
  end

  test "email is normalized to lowercase" do
    user = User.create!(email: "UPPER@EXAMPLE.COM")
    assert_equal "upper@example.com", user.email
  end

  test "has_role? returns true when role assigned" do
    @user.roles << @producer_role
    assert @user.has_role?(:producer)
  end

  test "has_role? returns false when role not assigned" do
    assert_not @user.has_role?(:producer)
  end

  test "has_role? accepts string" do
    @user.roles << @writer_role
    assert @user.has_role?("writer")
  end

  test "can have multiple roles" do
    @user.roles << @producer_role
    @user.roles << @writer_role
    assert @user.has_role?(:producer)
    assert @user.has_role?(:writer)
  end
end
