# frozen_string_literal: true

require "test_helper"

class SceneTest < ActiveSupport::TestCase
  def setup
    @project = Project.create!(title: "Back to the Future")
  end

  test "requires name and number" do
    scene = Scene.new(project: @project)
    assert_not scene.valid?
    assert_includes scene.errors[:name],   "can't be blank"
    assert_includes scene.errors[:number], "can't be blank"
  end

  test "defaults to draft status" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1)
    assert_equal "draft", scene.status
  end

  test "draft? predicate" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1)
    assert scene.draft?
    assert_not scene.released?
  end

  test "submit! transitions to ready_for_review" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1)
    scene.submit!
    assert_equal "ready_for_review", scene.status
    assert_not_nil scene.submitted_at
  end

  test "release! transitions to released" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1)
    scene.submit!
    scene.release!
    assert_equal "released", scene.status
    assert_not_nil scene.released_at
  end

  test "reject! returns scene to draft" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1)
    scene.submit!
    scene.reject!(notes: "Needs more tension")
    assert_equal "draft", scene.status
    assert_equal "Needs more tension", scene.rejection_notes
  end

  test "revision_number increments on submit!" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1)
    assert_equal 1, scene.revision_number
    scene.submit!
    scene.reject!
    scene.submit!
    assert_equal 2, scene.revision_number
  end

  test "released scope" do
    Scene.create!(project: @project, name: "Draft",    number: 1)
    released = Scene.create!(project: @project, name: "Released", number: 2)
    released.submit!
    released.release!
    assert_equal 1, Scene.released.count
  end

  test "beat_structure_list returns parsed JSON" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1,
                          beat_structure: '["Setup","Confrontation","Resolution"]')
    assert_equal 3, scene.beat_structure_list.length
  end
end
