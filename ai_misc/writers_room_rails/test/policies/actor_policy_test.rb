require "test_helper"

class ActorPolicyTest < ActiveSupport::TestCase
  def setup
    Role.find_or_create_by!(name: "producer")
    Role.find_or_create_by!(name: "writer")
    Role.find_or_create_by!(name: "casting_director")
    Role.find_or_create_by!(name: "director")
    Role.find_or_create_by!(name: "actor")

    @producer    = User.create!(email: "producer@test.com")
    @writer      = User.create!(email: "writer@test.com")
    @casting_dir = User.create!(email: "casting@test.com")
    @director    = User.create!(email: "director@test.com")
    @actor_user  = User.create!(email: "actor@test.com")

    @producer.roles    << Role.find_by!(name: "producer")
    @writer.roles      << Role.find_by!(name: "writer")
    @casting_dir.roles << Role.find_by!(name: "casting_director")
    @director.roles    << Role.find_by!(name: "director")
    @actor_user.roles  << Role.find_by!(name: "actor")

    @actor = Actor.create!(name: "Test Actor")
  end

  test "producer can manage actors" do
    policy = ActorPolicy.new(@producer, @actor)
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "writer can manage actors" do
    policy = ActorPolicy.new(@writer, @actor)
    assert policy.create?
    assert policy.update?
  end

  test "casting director can create actors" do
    policy = ActorPolicy.new(@casting_dir, @actor)
    assert policy.create?
  end

  test "director can only read actors" do
    policy = ActorPolicy.new(@director, @actor)
    assert policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "actor user cannot create actors" do
    policy = ActorPolicy.new(@actor_user, @actor)
    assert_not policy.create?
    assert_not policy.destroy?
  end
end
