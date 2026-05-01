require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  test "requires name" do
    character = Character.new
    assert_not character.valid?
    assert_includes character.errors[:name], "can't be blank"
  end

  test "token counts default to zero" do
    character = Character.create!(name: "Marty McFly")
    assert_equal 0, character.input_tokens
    assert_equal 0, character.output_tokens
    assert_equal 0, character.total_tokens
  end

  test "token counts must be non-negative" do
    character = Character.new(name: "Test", input_tokens: -1)
    assert_not character.valid?
  end

  test "has many castings" do
    character = Character.create!(name: "Marty McFly")
    assert_respond_to character, :castings
  end

  test "has many actors through castings" do
    character = Character.create!(name: "Marty McFly")
    assert_respond_to character, :actors
  end

  test "has many projects through castings" do
    character = Character.create!(name: "Marty McFly")
    assert_respond_to character, :projects
  end

  test "external_want and internal_need are stored" do
    character = Character.create!(
      name: "Marty McFly",
      external_want: "Get back to 1985",
      internal_need: "Learn that actions have consequences"
    )
    assert_equal "Get back to 1985", character.external_want
    assert_equal "Learn that actions have consequences", character.internal_need
  end
end
