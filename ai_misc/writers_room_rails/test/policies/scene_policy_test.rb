require "test_helper"

class ScenePolicyTest < ActiveSupport::TestCase
  def setup
    Role.find_or_create_by!(name: "producer")
    Role.find_or_create_by!(name: "writer")
    Role.find_or_create_by!(name: "director")
    Role.find_or_create_by!(name: "actor")

    @producer = User.create!(email: "sp_producer@test.com")
    @writer   = User.create!(email: "sp_writer@test.com")
    @director = User.create!(email: "sp_director@test.com")

    @producer.roles << Role.find_by!(name: "producer")
    @writer.roles   << Role.find_by!(name: "writer")
    @director.roles << Role.find_by!(name: "director")

    @project       = Project.create!(title: "Test", prep_status: "concept")
    @ready_project = Project.create!(title: "Ready", prep_status: "ready")
    @scene         = Scene.new(project: @ready_project, name: "Scene 1", number: 1)
    @draft_scene   = Scene.create!(project: @ready_project, name: "Draft", number: 2)
  end

  test "create requires project to be ready" do
    scene_on_concept = Scene.new(project: @project, name: "X", number: 1)
    policy = ScenePolicy.new(@producer, scene_on_concept)
    assert_not policy.create?
  end

  test "producer can create scene on ready project" do
    assert ScenePolicy.new(@producer, @scene).create?
  end

  test "writer can create scene on ready project" do
    assert ScenePolicy.new(@writer, @scene).create?
  end

  test "director cannot create scenes" do
    assert_not ScenePolicy.new(@director, @scene).create?
  end

  test "director can release scenes" do
    assert ScenePolicy.new(@director, @draft_scene).release?
  end

  test "director cannot destroy scenes" do
    assert_not ScenePolicy.new(@director, @draft_scene).destroy?
  end
end
