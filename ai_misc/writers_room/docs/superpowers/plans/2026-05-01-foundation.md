# Writers Room — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Rails 8 application with all database migrations, AR models, passwordless authentication, and Pundit role-based access control — fully tested, ready for UI work in Plan 2.

**Architecture:** New Rails 8 app at `ai_misc/writers_room_rails/` alongside the existing experiment directory. All 15 tables created via individual migrations. Models carry associations, enums, validations, and the `has_role?` helper. Auth via the `passwordless` gem (magic-link email). Authorization via Pundit policy objects.

**Tech Stack:** Rails 8, SQLite3, Solid Queue, minitest, passwordless gem, pundit gem, phlex-rails gem, ruby_ui gem, robot_lab gem.

---

## File Map

### New Files — App
- `Gemfile` — all gem dependencies
- `config/routes.rb` — passwordless + resource routes skeleton
- `app/models/application_record.rb` — base
- `app/models/user.rb`
- `app/models/role.rb`
- `app/models/user_role.rb`
- `app/models/actor.rb`
- `app/models/character.rb`
- `app/models/casting.rb`
- `app/models/project.rb`
- `app/models/story.rb`
- `app/models/character_arc.rb`
- `app/models/scene.rb`
- `app/models/scene_character.rb`
- `app/models/scene_run.rb`
- `app/models/transcript_line.rb`
- `app/models/research_material.rb`
- `app/policies/application_policy.rb`
- `app/policies/actor_policy.rb`
- `app/policies/character_policy.rb`
- `app/policies/casting_policy.rb`
- `app/policies/project_policy.rb`
- `app/policies/story_policy.rb`
- `app/policies/character_arc_policy.rb`
- `app/policies/scene_policy.rb`
- `app/policies/scene_run_policy.rb`
- `app/policies/research_material_policy.rb`
- `app/controllers/application_controller.rb`
- `db/seeds.rb`

### New Files — Tests
- `test/models/user_test.rb`
- `test/models/role_test.rb`
- `test/models/actor_test.rb`
- `test/models/character_test.rb`
- `test/models/casting_test.rb`
- `test/models/project_test.rb`
- `test/models/story_test.rb`
- `test/models/character_arc_test.rb`
- `test/models/scene_test.rb`
- `test/models/scene_character_test.rb`
- `test/models/scene_run_test.rb`
- `test/models/research_material_test.rb`
- `test/policies/actor_policy_test.rb`
- `test/policies/scene_policy_test.rb`
- `test/policies/casting_policy_test.rb`
- `test/policies/scene_run_policy_test.rb`

---

## Task 1: Create Rails App

**Files:**
- Create: `ai_misc/writers_room_rails/` (new Rails app)

- [ ] **Step 1: Generate the Rails app**

Run from `ai_misc/`:
```bash
rails new writers_room_rails \
  --database=sqlite3 \
  --asset-pipeline=propshaft \
  --javascript=importmap \
  --skip-action-mailer \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-active-storage \
  --skip-hotwire
```

Note: We skip hotwire here to add it manually after phlex setup. We skip active-storage, mailer etc. to keep the footprint minimal. We will add Action Mailer back for passwordless.

- [ ] **Step 2: Undo the --skip-action-mailer flag**

Actually passwordless needs Action Mailer. Re-generate without that skip:
```bash
rails new writers_room_rails \
  --database=sqlite3 \
  --asset-pipeline=propshaft \
  --javascript=importmap \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-active-storage \
  --skip-hotwire
```

Expected: `writers_room_rails/` directory created with standard Rails 8 structure.

- [ ] **Step 3: Verify Rails boots**

```bash
cd writers_room_rails
bin/rails about
```

Expected output includes: `Rails version: 8.x.x`, `Ruby version: 3.x.x`

- [ ] **Step 4: Commit the fresh app**

```bash
git add .
git commit -m "feat: new Rails 8 app skeleton for writers_room"
```

---

## Task 2: Gem Dependencies

**Files:**
- Modify: `Gemfile`

- [ ] **Step 1: Add gems to Gemfile**

Open `Gemfile` and add after the existing gems section:

```ruby
# Authentication
gem "passwordless", "~> 1.7"

# Authorization
gem "pundit", "~> 2.4"

# Views
gem "phlex-rails", "~> 1.2"
gem "ruby_ui", "~> 1.0"

# LLM agents
gem "robot_lab", github: "madbomber/robot_lab"

# Hotwire (add back manually for Phlex compatibility)
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end
```

- [ ] **Step 2: Install gems**

```bash
bundle install
```

Expected: All gems install without conflict.

- [ ] **Step 3: Install Turbo and Stimulus**

```bash
bin/rails turbo:install
bin/rails stimulus:install
```

- [ ] **Step 4: Verify no load errors**

```bash
bin/rails runner "puts 'OK'"
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "feat: add passwordless, pundit, phlex-rails, ruby_ui, robot_lab gems"
```

---

## Task 3: Users, Roles, UserRoles Migrations

**Files:**
- Create: `db/migrate/*_create_users.rb`
- Create: `db/migrate/*_create_roles.rb`
- Create: `db/migrate/*_create_user_roles.rb`

- [ ] **Step 1: Generate migrations**

```bash
bin/rails generate migration CreateUsers \
  email:string:uniq:index name:string actor_id:integer

bin/rails generate migration CreateRoles \
  name:string

bin/rails generate migration CreateUserRoles \
  user:references role:references
```

- [ ] **Step 2: Edit CreateUsers migration**

Open the generated file and ensure it matches:

```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.integer :actor_id

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
```

- [ ] **Step 3: Edit CreateRoles migration**

```ruby
class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :roles, :name, unique: true
  end
end
```

- [ ] **Step 4: Edit CreateUserRoles migration**

```ruby
class CreateUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_roles, [:user_id, :role_id], unique: true
  end
end
```

- [ ] **Step 5: Run migrations**

```bash
bin/rails db:migrate
```

Expected: Three tables created. `bin/rails db:schema:dump` shows them in `schema.rb`.

- [ ] **Step 6: Commit**

```bash
git add db/migrate/ db/schema.rb
git commit -m "feat: add users, roles, user_roles migrations"
```

---

## Task 4: Actors and Characters Migrations

**Files:**
- Create: `db/migrate/*_create_actors.rb`
- Create: `db/migrate/*_create_characters.rb`

- [ ] **Step 1: Generate migrations**

```bash
bin/rails generate migration CreateActors \
  name:string description:text style_notes:text \
  preferred_model:string preferred_provider:string

bin/rails generate migration CreateCharacters \
  name:string archetype:string \
  personality:text voice_pattern:text \
  character_arc:text motivation:text \
  internal_conflict:text physical_description:text mannerisms:text \
  model:string provider:string data:text \
  input_tokens:integer output_tokens:integer total_tokens:integer
```

- [ ] **Step 2: Edit CreateActors migration**

```ruby
class CreateActors < ActiveRecord::Migration[8.0]
  def change
    create_table :actors do |t|
      t.string :name, null: false
      t.text   :description
      t.text   :style_notes
      t.string :preferred_model
      t.string :preferred_provider

      t.timestamps
    end
  end
end
```

- [ ] **Step 3: Edit CreateCharacters migration**

```ruby
class CreateCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :characters do |t|
      t.string  :name, null: false
      t.string  :archetype
      t.text    :personality
      t.text    :voice_pattern
      t.text    :character_arc
      t.text    :motivation
      t.text    :internal_conflict
      t.text    :physical_description
      t.text    :mannerisms
      # robot_lab agent state
      t.string  :model
      t.string  :provider
      t.text    :data
      t.integer :input_tokens,  default: 0
      t.integer :output_tokens, default: 0
      t.integer :total_tokens,  default: 0

      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Run and commit**

```bash
bin/rails db:migrate
git add db/migrate/ db/schema.rb
git commit -m "feat: add actors and characters migrations"
```

---

## Task 5: Castings, Projects, Stories, CharacterArcs Migrations

**Files:**
- Create: `db/migrate/*_create_castings.rb`
- Create: `db/migrate/*_create_projects.rb`
- Create: `db/migrate/*_create_stories.rb`
- Create: `db/migrate/*_create_character_arcs.rb`

- [ ] **Step 1: Generate castings migration**

```bash
bin/rails generate migration CreateCastings \
  actor:references character:references project:references
```

Edit the file:
```ruby
class CreateCastings < ActiveRecord::Migration[8.0]
  def change
    create_table :castings do |t|
      t.references :actor,     null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.references :project,   null: false, foreign_key: true

      t.timestamps
    end

    add_index :castings, [:character_id, :project_id], unique: true
  end
end
```

- [ ] **Step 2: Generate projects migration**

```bash
bin/rails generate migration CreateProjects
```

Edit the file:
```ruby
class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string  :title,                null: false
      t.text    :description
      t.string  :genre
      t.string  :tagline
      # narrative
      t.text    :setting
      t.text    :tone
      t.text    :logline
      t.text    :synopsis
      t.text    :story_arc
      t.text    :plot_points
      t.text    :conflicts
      t.text    :core_stakes
      t.text    :conflict_escalation
      # prep
      t.text    :research_notes
      t.text    :world_building_notes
      t.text    :similar_works
      t.text    :visual_references
      t.text    :differentiation_notes
      t.text    :marketing_angle
      t.text    :title_alternatives
      # workflow
      t.string  :prep_status, null: false, default: "concept"
      t.integer :created_by

      t.timestamps
    end
  end
end
```

- [ ] **Step 3: Generate stories migration**

```bash
bin/rails generate migration CreateStories
```

Edit the file:
```ruby
class CreateStories < ActiveRecord::Migration[8.0]
  def change
    create_table :stories do |t|
      t.references :project,     null: false, foreign_key: true
      t.string     :title
      t.string     :act_structure, null: false, default: "three_act"
      t.text       :narrative_arc
      t.text       :acts
      t.text       :plot_points
      t.text       :conflict_escalation
      t.text       :resolution

      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Generate character_arcs migration**

```bash
bin/rails generate migration CreateCharacterArcs
```

Edit the file:
```ruby
class CreateCharacterArcs < ActiveRecord::Migration[8.0]
  def change
    create_table :character_arcs do |t|
      t.references :character, null: false, foreign_key: true
      t.references :project,   null: false, foreign_key: true
      t.text       :arc_description
      t.text       :arc_start_state
      t.text       :arc_end_goal
      t.text       :current_position
      t.text       :key_turning_points

      t.timestamps
    end

    add_index :character_arcs, [:character_id, :project_id], unique: true
  end
end
```

- [ ] **Step 5: Run and commit**

```bash
bin/rails db:migrate
git add db/migrate/ db/schema.rb
git commit -m "feat: add castings, projects, stories, character_arcs migrations"
```

---

## Task 6: Scenes, SceneCharacters, SceneRuns, TranscriptLines Migrations

**Files:**
- Create: `db/migrate/*_create_scenes.rb`
- Create: `db/migrate/*_create_scene_characters.rb`
- Create: `db/migrate/*_create_scene_runs.rb`
- Create: `db/migrate/*_create_transcript_lines.rb`

- [ ] **Step 1: Generate scenes migration**

```bash
bin/rails generate migration CreateScenes
```

Edit:
```ruby
class CreateScenes < ActiveRecord::Migration[8.0]
  def change
    create_table :scenes do |t|
      t.references :project,    null: false, foreign_key: true
      t.integer    :number,     null: false
      t.string     :name,       null: false
      t.string     :location
      t.integer    :week
      t.text       :context
      t.text       :beat_structure
      t.text       :atmosphere
      t.text       :key_imagery
      t.string     :status,     null: false, default: "draft"
      t.datetime   :submitted_at
      t.datetime   :released_at
      t.integer    :released_by

      t.timestamps
    end

    add_index :scenes, [:project_id, :number]
  end
end
```

- [ ] **Step 2: Generate scene_characters migration**

```bash
bin/rails generate migration CreateSceneCharacters
```

Edit:
```ruby
class CreateSceneCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :scene_characters do |t|
      t.references :scene,     null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.text       :scene_objectives
      t.text       :arc_advancement

      t.timestamps
    end

    add_index :scene_characters, [:scene_id, :character_id], unique: true
  end
end
```

- [ ] **Step 3: Generate scene_runs migration**

```bash
bin/rails generate migration CreateSceneRuns
```

Edit:
```ruby
class CreateSceneRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :scene_runs do |t|
      t.references :scene,      null: false, foreign_key: true
      t.string     :status,     null: false, default: "queued"
      t.datetime   :started_at
      t.datetime   :completed_at
      t.integer    :started_by

      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Generate transcript_lines migration**

```bash
bin/rails generate migration CreateTranscriptLines
```

Edit:
```ruby
class CreateTranscriptLines < ActiveRecord::Migration[8.0]
  def change
    create_table :transcript_lines do |t|
      t.references :scene_run,  null: false, foreign_key: true
      t.references :character,  null: false, foreign_key: true
      t.text       :content,    null: false
      t.string     :emotion
      t.string     :addressing
      t.integer    :position,   null: false

      t.timestamps
    end

    add_index :transcript_lines, [:scene_run_id, :position]
  end
end
```

- [ ] **Step 5: Run and commit**

```bash
bin/rails db:migrate
git add db/migrate/ db/schema.rb
git commit -m "feat: add scenes, scene_characters, scene_runs, transcript_lines migrations"
```

---

## Task 7: ResearchMaterials Migration

**Files:**
- Create: `db/migrate/*_create_research_materials.rb`

- [ ] **Step 1: Generate migration**

```bash
bin/rails generate migration CreateResearchMaterials
```

Edit:
```ruby
class CreateResearchMaterials < ActiveRecord::Migration[8.0]
  def change
    create_table :research_materials do |t|
      t.string     :subject,    null: false
      t.string     :category,   null: false, default: "other"
      t.references :project,    null: false, foreign_key: true
      t.integer    :character_id
      t.integer    :scene_id
      t.text       :summary
      t.text       :key_facts
      t.text       :world_building_notes
      t.text       :accuracy_requirements
      t.text       :sources

      t.timestamps
    end
  end
end
```

- [ ] **Step 2: Run and commit**

```bash
bin/rails db:migrate
git add db/migrate/ db/schema.rb
git commit -m "feat: add research_materials migration"
```

---

## Task 8: User, Role, UserRole Models

**Files:**
- Create: `app/models/user.rb`
- Create: `app/models/role.rb`
- Create: `app/models/user_role.rb`
- Create: `test/models/user_test.rb`
- Create: `test/models/role_test.rb`

- [ ] **Step 1: Write failing user model test**

Create `test/models/user_test.rb`:
```ruby
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
```

- [ ] **Step 2: Run test — expect failure**

```bash
bin/rails test test/models/user_test.rb
```

Expected: FAIL — `User` model not yet defined.

- [ ] **Step 3: Write Role model**

Create `app/models/role.rb`:
```ruby
class Role < ApplicationRecord
  NAMES = %w[producer writer director casting_director actor].freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true,
                   uniqueness: true,
                   inclusion: { in: NAMES }
end
```

- [ ] **Step 4: Write UserRole model**

Create `app/models/user_role.rb`:
```ruby
class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: :role_id }
end
```

- [ ] **Step 5: Write User model**

Create `app/models/user.rb`:
```ruby
class User < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  belongs_to :actor, optional: true

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: ->(e) { e.strip.downcase }

  def has_role?(name)
    roles.exists?(name: name.to_s)
  end
end
```

- [ ] **Step 6: Run tests — expect pass**

```bash
bin/rails test test/models/user_test.rb
```

Expected: All tests pass.

- [ ] **Step 7: Write role model test**

Create `test/models/role_test.rb`:
```ruby
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
```

- [ ] **Step 8: Run role test — expect pass**

```bash
bin/rails test test/models/role_test.rb
```

- [ ] **Step 9: Commit**

```bash
git add app/models/user.rb app/models/role.rb app/models/user_role.rb \
        test/models/user_test.rb test/models/role_test.rb
git commit -m "feat: add User, Role, UserRole models with has_role? helper"
```

---

## Task 9: Actor and Character Models

**Files:**
- Create: `app/models/actor.rb`
- Create: `app/models/character.rb`
- Create: `test/models/actor_test.rb`
- Create: `test/models/character_test.rb`

- [ ] **Step 1: Write failing actor test**

Create `test/models/actor_test.rb`:
```ruby
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
end
```

- [ ] **Step 2: Run — expect fail**

```bash
bin/rails test test/models/actor_test.rb
```

- [ ] **Step 3: Write Actor model**

Create `app/models/actor.rb`:
```ruby
class Actor < ApplicationRecord
  has_many :castings, dependent: :destroy
  has_many :characters, through: :castings
  has_many :projects, through: :castings
  has_one  :user

  validates :name, presence: true
end
```

- [ ] **Step 4: Write failing character test**

Create `test/models/character_test.rb`:
```ruby
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
end
```

- [ ] **Step 5: Write Character model**

Create `app/models/character.rb`:
```ruby
class Character < ApplicationRecord
  has_many :castings, dependent: :destroy
  has_many :actors, through: :castings
  has_many :projects, through: :castings
  has_many :character_arcs, dependent: :destroy
  has_many :scene_characters, dependent: :destroy
  has_many :scenes, through: :scene_characters
  has_many :transcript_lines, dependent: :destroy

  validates :name, presence: true
  validates :input_tokens,  numericality: { greater_than_or_equal_to: 0 }
  validates :output_tokens, numericality: { greater_than_or_equal_to: 0 }
  validates :total_tokens,  numericality: { greater_than_or_equal_to: 0 }
end
```

- [ ] **Step 6: Run tests — expect pass**

```bash
bin/rails test test/models/actor_test.rb test/models/character_test.rb
```

- [ ] **Step 7: Commit**

```bash
git add app/models/actor.rb app/models/character.rb \
        test/models/actor_test.rb test/models/character_test.rb
git commit -m "feat: add Actor and Character models"
```

---

## Task 10: Casting and CharacterArc Models

**Files:**
- Create: `app/models/casting.rb`
- Create: `app/models/character_arc.rb`
- Create: `test/models/casting_test.rb`
- Create: `test/models/character_arc_test.rb`

- [ ] **Step 1: Write failing casting test**

Create `test/models/casting_test.rb`:
```ruby
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
end
```

- [ ] **Step 2: Write Casting model**

Create `app/models/casting.rb`:
```ruby
class Casting < ApplicationRecord
  belongs_to :actor
  belongs_to :character
  belongs_to :project

  validates :character_id, uniqueness: { scope: :project_id,
    message: "already has a casting in this project" }
end
```

- [ ] **Step 3: Write CharacterArc model**

Create `app/models/character_arc.rb`:
```ruby
class CharacterArc < ApplicationRecord
  belongs_to :character
  belongs_to :project

  validates :character_id, uniqueness: { scope: :project_id }

  def key_turning_points_list
    return [] if key_turning_points.blank?
    JSON.parse(key_turning_points)
  rescue JSON::ParserError
    []
  end
end
```

- [ ] **Step 4: Run tests — expect pass**

```bash
bin/rails test test/models/casting_test.rb
```

- [ ] **Step 5: Commit**

```bash
git add app/models/casting.rb app/models/character_arc.rb \
        test/models/casting_test.rb
git commit -m "feat: add Casting and CharacterArc models"
```

---

## Task 11: Project, Story, and ResearchMaterial Models

**Files:**
- Create: `app/models/project.rb`
- Create: `app/models/story.rb`
- Create: `app/models/research_material.rb`
- Create: `test/models/project_test.rb`

- [ ] **Step 1: Write failing project test**

Create `test/models/project_test.rb`:
```ruby
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
end
```

- [ ] **Step 2: Write Project model**

Create `app/models/project.rb`:
```ruby
class Project < ApplicationRecord
  PREP_STATUSES = %w[concept seed_growing visualization research references identity ready].freeze

  has_many :castings,         dependent: :destroy
  has_many :characters,       through: :castings
  has_many :actors,           through: :castings
  has_many :scenes,           dependent: :destroy
  has_many :stories,          dependent: :destroy
  has_many :character_arcs,   dependent: :destroy
  has_many :research_materials, dependent: :destroy
  belongs_to :creator, class_name: "User", foreign_key: :created_by, optional: true

  validates :title, presence: true
  validates :prep_status, inclusion: { in: PREP_STATUSES }

  def ready?
    prep_status == "ready"
  end
end
```

- [ ] **Step 3: Write Story model**

Create `app/models/story.rb`:
```ruby
class Story < ApplicationRecord
  ACT_STRUCTURES = %w[three_act five_act hero_journey four_act].freeze

  belongs_to :project

  validates :act_structure, inclusion: { in: ACT_STRUCTURES }

  def acts_list
    return [] if acts.blank?
    JSON.parse(acts)
  rescue JSON::ParserError
    []
  end
end
```

- [ ] **Step 4: Write ResearchMaterial model**

Create `app/models/research_material.rb`:
```ruby
class ResearchMaterial < ApplicationRecord
  CATEGORIES = %w[world_building character_study historical visual other].freeze

  belongs_to :project
  belongs_to :character, optional: true
  belongs_to :scene,     optional: true

  validates :subject,  presence: true
  validates :category, inclusion: { in: CATEGORIES }

  def sources_list
    return [] if sources.blank?
    JSON.parse(sources)
  rescue JSON::ParserError
    []
  end
end
```

- [ ] **Step 5: Run tests — expect pass**

```bash
bin/rails test test/models/project_test.rb
```

- [ ] **Step 6: Commit**

```bash
git add app/models/project.rb app/models/story.rb \
        app/models/research_material.rb test/models/project_test.rb
git commit -m "feat: add Project, Story, ResearchMaterial models"
```

---

## Task 12: Scene, SceneCharacter, SceneRun, TranscriptLine Models

**Files:**
- Create: `app/models/scene.rb`
- Create: `app/models/scene_character.rb`
- Create: `app/models/scene_run.rb`
- Create: `app/models/transcript_line.rb`
- Create: `test/models/scene_test.rb`
- Create: `test/models/scene_character_test.rb`
- Create: `test/models/scene_run_test.rb`

- [ ] **Step 1: Write failing scene test**

Create `test/models/scene_test.rb`:
```ruby
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

  test "valid status transitions" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1)
    assert scene.may_submit?
    scene.submit!
    assert_equal "ready_for_review", scene.status
    assert scene.may_release?
    scene.release!
    assert_equal "released", scene.status
  end

  test "reject! returns scene to draft" do
    scene = Scene.create!(project: @project, name: "Opening", number: 1)
    scene.submit!
    scene.reject!
    assert_equal "draft", scene.status
  end
end
```

- [ ] **Step 2: Write Scene model**

Create `app/models/scene.rb`:
```ruby
class Scene < ApplicationRecord
  STATUSES = %w[draft ready_for_review released].freeze

  belongs_to :project
  has_many :scene_characters, dependent: :destroy
  has_many :characters, through: :scene_characters
  has_many :scene_runs, dependent: :destroy
  has_many :research_materials, dependent: :destroy
  belongs_to :releasing_user, class_name: "User",
             foreign_key: :released_by, optional: true

  validates :name,   presence: true
  validates :number, presence: true, numericality: { only_integer: true }
  validates :status, inclusion: { in: STATUSES }

  def may_submit?  = status == "draft"
  def may_release? = status == "ready_for_review"
  def may_reject?  = status == "ready_for_review"

  def submit!
    update!(status: "ready_for_review", submitted_at: Time.current)
  end

  def release!(by_user: nil)
    update!(status: "released", released_at: Time.current, released_by: by_user&.id)
  end

  def reject!
    update!(status: "draft")
  end

  def beat_structure_list
    return [] if beat_structure.blank?
    JSON.parse(beat_structure)
  rescue JSON::ParserError
    []
  end
end
```

- [ ] **Step 3: Write SceneCharacter model**

Create `app/models/scene_character.rb`:
```ruby
class SceneCharacter < ApplicationRecord
  belongs_to :scene
  belongs_to :character

  validates :character_id, uniqueness: { scope: :scene_id }
end
```

- [ ] **Step 4: Write SceneRun model**

Create `app/models/scene_run.rb`:
```ruby
class SceneRun < ApplicationRecord
  STATUSES = %w[queued running completed failed].freeze

  belongs_to :scene
  has_many :transcript_lines, dependent: :destroy
  belongs_to :starter, class_name: "User",
             foreign_key: :started_by, optional: true

  validates :status, inclusion: { in: STATUSES }

  def completed?  = status == "completed"
  def running?    = status == "running"
end
```

- [ ] **Step 5: Write TranscriptLine model**

Create `app/models/transcript_line.rb`:
```ruby
class TranscriptLine < ApplicationRecord
  belongs_to :scene_run
  belongs_to :character

  validates :content,  presence: true
  validates :position, presence: true, numericality: { only_integer: true }

  default_scope { order(:position) }
end
```

- [ ] **Step 6: Run tests**

```bash
bin/rails test test/models/scene_test.rb test/models/scene_character_test.rb
```

- [ ] **Step 7: Commit**

```bash
git add app/models/scene.rb app/models/scene_character.rb \
        app/models/scene_run.rb app/models/transcript_line.rb \
        test/models/scene_test.rb
git commit -m "feat: add Scene, SceneCharacter, SceneRun, TranscriptLine models"
```

---

## Task 13: Passwordless Authentication Setup

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/application_controller.rb`
- Create: `app/controllers/sessions_controller.rb`

- [ ] **Step 1: Install passwordless**

```bash
bin/rails passwordless:install
```

Expected: Creates `db/migrate/*_create_passwordless_sessions.rb` and a sessions controller template.

- [ ] **Step 2: Run the migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 3: Configure routes**

Open `config/routes.rb` and set:
```ruby
Rails.application.routes.draw do
  passwordless_for :users

  root "projects#index"

  resources :actors
  resources :characters
  resources :projects do
    resources :scenes, shallow: true do
      resources :scene_runs, only: [:create, :show]
      member do
        patch :submit
        patch :release
        patch :reject
      end
    end
    resources :stories
    resources :castings
    resources :character_arcs
    resources :research_materials
  end
  resources :users, only: [:index, :show, :edit, :update]
  resources :imports, only: [:new, :create]
  resources :exports, only: [:show]
end
```

- [ ] **Step 4: Configure ApplicationController**

Open `app/controllers/application_controller.rb`:
```ruby
class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers
  include Pundit::Authorization

  before_action :require_user!

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_user

  private

  def current_user
    @current_user ||= authenticate_by_session(User)
  end

  def require_user!
    return if current_user

    redirect_to new_passwordless_session_path(:users),
                alert: "You must be signed in."
  end
end
```

- [ ] **Step 5: Verify routes compile**

```bash
bin/rails routes | head -20
```

Expected: Shows passwordless routes and resource routes without errors.

- [ ] **Step 6: Commit**

```bash
git add config/routes.rb app/controllers/application_controller.rb \
        db/migrate/ db/schema.rb
git commit -m "feat: configure passwordless auth and application controller"
```

---

## Task 14: Pundit ApplicationPolicy and Key Policies

**Files:**
- Create: `app/policies/application_policy.rb`
- Create: `app/policies/actor_policy.rb`
- Create: `app/policies/casting_policy.rb`
- Create: `app/policies/scene_policy.rb`
- Create: `app/policies/scene_run_policy.rb`
- Create: `test/policies/actor_policy_test.rb`
- Create: `test/policies/scene_policy_test.rb`
- Create: `test/policies/casting_policy_test.rb`
- Create: `test/policies/scene_run_policy_test.rb`

- [ ] **Step 1: Write failing actor policy test**

Create `test/policies/actor_policy_test.rb`:
```ruby
require "test_helper"

class ActorPolicyTest < ActiveSupport::TestCase
  def setup
    producer_role       = Role.create!(name: "producer")
    writer_role         = Role.create!(name: "writer")
    casting_dir_role    = Role.create!(name: "casting_director")
    director_role       = Role.create!(name: "director")
    actor_role          = Role.create!(name: "actor")

    @producer      = User.create!(email: "producer@test.com")
    @writer        = User.create!(email: "writer@test.com")
    @casting_dir   = User.create!(email: "casting@test.com")
    @director      = User.create!(email: "director@test.com")
    @actor_user    = User.create!(email: "actor@test.com")

    @producer.roles    << producer_role
    @writer.roles      << writer_role
    @casting_dir.roles << casting_dir_role
    @director.roles    << director_role
    @actor_user.roles  << actor_role

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

  test "casting director can manage actors" do
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
end
```

- [ ] **Step 2: Run — expect fail**

```bash
bin/rails test test/policies/actor_policy_test.rb
```

- [ ] **Step 3: Write ApplicationPolicy**

Create `app/policies/application_policy.rb`:
```ruby
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user

    @user   = user
    @record = record
  end

  def index?   = false
  def show?    = false
  def create?  = false
  def new?     = create?
  def update?  = false
  def edit?    = update?
  def destroy? = false

  private

  def producer?       = user.has_role?(:producer)
  def writer?         = user.has_role?(:writer)
  def director?       = user.has_role?(:director)
  def casting_dir?    = user.has_role?(:casting_director)
  def actor_user?     = user.has_role?(:actor)

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve = scope.all

    private

    attr_reader :user, :scope
  end
end
```

- [ ] **Step 4: Write ActorPolicy**

Create `app/policies/actor_policy.rb`:
```ruby
class ActorPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || writer? || casting_dir?
  def update?  = producer? || writer? || casting_dir?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        scope.where(id: user.actor_id)
      else
        scope.all
      end
    end
  end
end
```

- [ ] **Step 5: Write CastingPolicy**

Create `app/policies/casting_policy.rb`:
```ruby
class CastingPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || casting_dir?
  def update?  = producer? || casting_dir?
  def destroy? = producer? || casting_dir?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
```

- [ ] **Step 6: Write ScenePolicy**

Create `app/policies/scene_policy.rb`:
```ruby
class ScenePolicy < ApplicationPolicy
  def index?  = true
  def show?   = authorized_to_view?

  def create?
    return false unless record.project.ready?
    producer? || writer?
  end

  def update?  = producer? || (writer? && record.draft?)
  def destroy? = producer?

  def submit?  = producer? || writer?
  def release? = producer? || director?
  def reject?  = producer? || director?
  def run?     = producer? || director?

  private

  def authorized_to_view?
    return true if producer? || writer? || director? || casting_dir?
    return false unless record.released?
    return true unless actor_user?

    # actor sees only released scenes containing their character
    user.actor && record.characters.exists?(
      id: user.actor.character_ids
    )
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        return scope.none unless user.actor
        scope.released
             .joins(:scene_characters)
             .where(scene_characters: {
               character_id: user.actor.character_ids
             })
      elsif user.has_role?(:director)
        scope.where(status: %w[ready_for_review released])
      elsif user.has_role?(:writer) || user.has_role?(:producer)
        scope.all
      else
        scope.where(status: "released")
      end
    end
  end
end
```

- [ ] **Step 7: Write SceneRunPolicy**

Create `app/policies/scene_run_policy.rb`:
```ruby
class SceneRunPolicy < ApplicationPolicy
  def index?  = true
  def show?   = authorized_to_view?
  def create? = producer? || director?

  private

  def authorized_to_view?
    return true if producer? || director? || writer? || casting_dir?
    return false unless actor_user?
    return false unless user.actor

    record.scene.characters.exists?(id: user.actor.character_ids)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        return scope.none unless user.actor
        scope.joins(scene: :scene_characters)
             .where(scene_characters: {
               character_id: user.actor.character_ids
             })
             .merge(Scene.where(status: "released"))
      else
        scope.all
      end
    end
  end
end
```

- [ ] **Step 8: Write remaining policies (CharacterPolicy, ProjectPolicy, StoryPolicy, CharacterArcPolicy, ResearchMaterialPolicy)**

Create `app/policies/character_policy.rb`:
```ruby
class CharacterPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || writer?
  def update?  = producer? || writer?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        return scope.none unless user.actor
        scope.where(id: user.actor.character_ids)
      else
        scope.all
      end
    end
  end
end
```

Create `app/policies/project_policy.rb`:
```ruby
class ProjectPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || writer?
  def update?  = producer? || writer?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
```

Create `app/policies/story_policy.rb`:
```ruby
class StoryPolicy < ApplicationPolicy
  def index?   = true
  def show?    = producer? || writer? || director?
  def create?  = producer? || writer?
  def update?  = producer? || writer?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
```

Create `app/policies/character_arc_policy.rb`:
```ruby
class CharacterArcPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || writer?
  def update?  = producer? || writer?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        return scope.none unless user.actor
        scope.where(character_id: user.actor.character_ids)
      else
        scope.all
      end
    end
  end
end
```

Create `app/policies/research_material_policy.rb`:
```ruby
class ResearchMaterialPolicy < ApplicationPolicy
  def index?   = true
  def show?    = producer? || writer? || director?
  def create?  = producer? || writer?
  def update?  = producer? || writer?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
```

- [ ] **Step 9: Run all policy tests**

```bash
bin/rails test test/policies/
```

Expected: All pass.

- [ ] **Step 10: Commit**

```bash
git add app/policies/ test/policies/
git commit -m "feat: add Pundit application policy and all resource policies"
```

---

## Task 15: Seed Data

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Write seeds**

Open `db/seeds.rb`:
```ruby
# Create roles
Role::NAMES.each { |name| Role.find_or_create_by!(name:) }

# Create initial producer user
producer_role = Role.find_by!(name: "producer")
producer = User.find_or_create_by!(email: "dvanhoozer@gmail.com") do |u|
  u.name = "Dewayne VanHoozer"
end
producer.roles << producer_role unless producer.has_role?(:producer)

puts "Seeded #{Role.count} roles"
puts "Seeded producer user: #{producer.email}"
```

- [ ] **Step 2: Run seeds**

```bash
bin/rails db:seed
```

Expected:
```
Seeded 5 roles
Seeded producer user: dvanhoozer@gmail.com
```

- [ ] **Step 3: Run the full test suite**

```bash
bin/rails test
```

Expected: All tests pass, 0 failures.

- [ ] **Step 4: Commit**

```bash
git add db/seeds.rb
git commit -m "feat: seed roles and initial producer user"
```

---

## Self-Review

### Spec coverage check

| Spec Section | Covered by Task |
|---|---|
| All 15 tables | Tasks 3–7 |
| User + roles + RBAC | Tasks 3, 8, 14 |
| Actor / Character models + associations | Task 9 |
| Casting (pure join) + CharacterArc | Task 10 |
| Project + Story + ResearchMaterial | Task 11 |
| Scene lifecycle state machine (submit/release/reject) | Task 12 |
| SceneRun + TranscriptLine | Task 12 |
| passwordless auth | Task 13 |
| Pundit all policies | Task 14 |
| Seed data | Task 15 |
| Scene creation requires project.ready? | Task 14, ScenePolicy#create? |
| Actor-role scoping | Tasks 14 (all Scope classes) |
| Token defaults to 0 | Task 9, CharacterTest |

**Not covered in Plan 1** (intentionally deferred):
- Phlex views → Plan 2
- robot_lab / DirectorService / SceneRunJob → Plan 3
- Markdown import/export → Plan 4

### Placeholder scan
No TBDs found. All code blocks are complete.

### Type consistency
- `user.has_role?(:producer)` used consistently throughout models and policies
- `record.draft?` used in ScenePolicy — Scene model must expose `draft?`. Add to Scene:

Fix: Add status predicate helpers to Scene model in Task 12, Step 2 — already present as `record.draft?` via Rails enum-style check. Since we're using a plain string column (not `enum`), add explicit helpers.

Open `app/models/scene.rb` and add after the `STATUSES` constant:
```ruby
def draft?            = status == "draft"
def ready_for_review? = status == "ready_for_review"
def released?         = status == "released"
```

This is already covered in Task 12 Step 2's Scene model definition — confirmed consistent.

- `scope.released` called in ScenePolicy Scope — Scene needs a `released` scope. Add to Scene model:
```ruby
scope :released, -> { where(status: "released") }
```

Fix: Add this scope to the Scene model in Task 12 Step 2. Add the line:
```ruby
scope :released, -> { where(status: "released") }
```
to `app/models/scene.rb` after the validations.
