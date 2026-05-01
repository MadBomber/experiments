# frozen_string_literal: true

require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "requires title" do
    project = Project.new
    assert_not project.valid?
    assert_includes project.errors[:title], "can't be blank"
  end

  test "defaults prep_status to concept" do
    project = Project.create!(title: "My Project")
    assert_equal "concept", project.prep_status
  end

  test "prep_status must be valid" do
    project = Project.new(title: "Test", prep_status: "unknown")
    assert_not project.valid?
  end

  test "ready? returns true only when prep_status is ready" do
    project = Project.create!(title: "Test", prep_status: "ready")
    assert project.ready?

    project.update!(prep_status: "concept")
    assert_not project.ready?
  end

  test "has many scenes" do
    project = Project.create!(title: "Test")
    assert_respond_to project, :scenes
  end

  test "has many stories" do
    project = Project.create!(title: "Test")
    assert_respond_to project, :stories
  end

  test "theme and thematic_question are stored" do
    project = Project.create!(
      title: "Test",
      theme: "Actions have consequences",
      thematic_question: "Can good intentions cause harm?"
    )
    assert_equal "Actions have consequences", project.theme
  end

  test "target_page_count and target_runtime_minutes are stored" do
    project = Project.create!(title: "Test", target_page_count: 110, target_runtime_minutes: 110)
    assert_equal 110, project.target_page_count
  end
end
