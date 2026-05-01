require "test_helper"

class CastingTest < ActiveSupport::TestCase
  def setup
    @actor     = Actor.create!(name: "Michael J. Fox")
    @character = Character.create!(name: "Marty McFly")
    @project   = Project.create!(title: "Back to the Future")
  end

  test "valid with actor, character, and project" do
    casting = Casting.new(actor: @actor, character: @character, project: @project)
    assert casting.valid?
  end

  test "character can only have one casting per project" do
    Casting.create!(actor: @actor, character: @character, project: @project)
    duplicate = Casting.new(actor: @actor, character: @character, project: @project)
    assert_not duplicate.valid?
  end

  test "requires actor" do
    casting = Casting.new(character: @character, project: @project)
    assert_not casting.valid?
  end

  test "requires character" do
    casting = Casting.new(actor: @actor, project: @project)
    assert_not casting.valid?
  end

  test "requires project" do
    casting = Casting.new(actor: @actor, character: @character)
    assert_not casting.valid?
  end
end
