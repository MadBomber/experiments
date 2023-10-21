# experiments/pg_vector/has_ancestry.rb

# A Concern used for any models implementing the ancestry gem.
module HasAncestry
  extend ActiveSupport::Concern

  included do
    has_ancestry orphan_strategy: :adopt, touch: true
    acts_as_list scope: [:ancestry]

    scope :self_and_descendants, -> { where(id: self_and_descendant_ids) }
  end

  def self_and_descendant_ids
    [id] + descendant_ids
  end

  def self_and_descendants
    self.class.where(id: self_and_descendant_ids)
  end

  def parents
    parent_records = []
    object = self
    while object.parent
      parent_records << object.parent
      object = object.parent
    end
    parent_records.reverse
  end

  def ancestor_ids_and_self
    ancestor_ids + [id]
  end

  def ancestors_and_self
    self.class.where(id: ancestor_ids_and_self)
  end
end

