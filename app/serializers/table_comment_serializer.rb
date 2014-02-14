class TableCommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :updated_at, :purpose, :version, :published, :status,
             :pro_votes, :con_votes,
             :table_number, :parent_theme_ids, :editable_by_user, :name, :elements


  def table_number
    object.author.last_name
  end

  def name
    "Table #{object.author.last_name}"
  end

  def parent_theme_ids
    # get the parent_theme_ids from the HABTM association
    object.parent_targets.map(&:parent_id)
  end

  def pro_votes
    object.pro_con_vote.try{|v| v.pro_votes} || 0
  end

  def con_votes
    object.pro_con_vote.try{|v| v.con_votes} || 0
  end

  def purpose
    object.purpose || 'Comment'
  end

  def editable_by_user
    (defined?(current_user).nil? || current_user.nil?) ? false : object.editable_by_user?(current_user)
  end

end
