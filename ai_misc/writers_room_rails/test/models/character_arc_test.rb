require "test_helper"

class CharacterArcTest < ActiveSupport::TestCase
  def setup
    @character = Character.create!(name: "Marty McFly")
    @project   = Project.create!(title: "Back to the Future")
  end

  test "valid with character and project" do
    arc = CharacterArc.new(character: @character, project: @project)
    assert arc.valid?
  end

  test "character can only have one arc per project" do
    CharacterArc.create!(character: @character, project: @project)
    duplicate = CharacterArc.new(character: @character, project: @project)
    assert_not duplicate.valid?
  end

  test "key_turning_points_list returns array from JSON" do
    arc = CharacterArc.create!(
      character: @character,
      project: @project,
      key_turning_points: '["Scene 2: realizes he erased himself","Scene 5: trusts Doc"]'
    )
    assert_equal 2, arc.key_turning_points_list.length
    assert_includes arc.key_turning_points_list, "Scene 2: realizes he erased himself"
  end

  test "key_turning_points_list returns empty array when nil" do
    arc = CharacterArc.create!(character: @character, project: @project)
    assert_equal [], arc.key_turning_points_list
  end

  test "role_in_story can be set" do
    arc = CharacterArc.create!(
      character: @character,
      project: @project,
      role_in_story: "protagonist"
    )
    assert_equal "protagonist", arc.role_in_story
  end
end
