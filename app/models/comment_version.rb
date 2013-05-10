class CommentVersion < Version
  self.table_name = :comment_versions
  self.sequence_name = :comment_version_id_seq

  attr_accessible :item_type, :item_id, :event, :whodunnit, :object


end