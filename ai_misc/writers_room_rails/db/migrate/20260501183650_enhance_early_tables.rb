class EnhanceEarlyTables < ActiveRecord::Migration[8.1]
  def change
    # Task 5 quality fixes: missing indexes
    add_index :projects, :prep_status
    add_index :projects, :created_by
    add_index :stories,  :act_structure

    # Arc Studio Pro research: Want vs. Need distinction on characters
    add_column :characters, :external_want, :text
    add_column :characters, :internal_need, :text

    # Arc Studio Pro research: theme fields on projects
    add_column :projects, :theme,             :text
    add_column :projects, :thematic_question, :text
    add_column :projects, :origin_approach,   :string

    # Arc Studio Pro research: story threading fields on stories
    add_column :stories, :plot_archetype, :string
    add_column :stories, :a_story,        :text
    add_column :stories, :b_story,        :text

    # Arc Studio Pro research: character role in story (per-project arc)
    add_column :character_arcs, :role_in_story, :string
  end
end
