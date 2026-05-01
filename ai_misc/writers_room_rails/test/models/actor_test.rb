require "test_helper"

class ActorTest < ActiveSupport::TestCase
  test "requires name" do
    actor = Actor.new
    assert_not actor.valid?
    assert_includes actor.errors[:name], "can't be blank"
  end

  test "has many characters through castings" do
    actor = Actor.create!(name: "Michael J. Fox")
    assert_respond_to actor, :characters
  end

  test "has many projects through castings" do
    actor = Actor.create!(name: "Michael J. Fox")
    assert_respond_to actor, :projects
  end

  test "has one user" do
    actor = Actor.create!(name: "Michael J. Fox")
    assert_respond_to actor, :user
  end
end
