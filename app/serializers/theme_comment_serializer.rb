class ThemeCommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :updated_at, :purpose,
             :version, :tag_name,
             :editable_by_user, :name, :code, :published, :status,
             :bookmark, :parent_theme_ids, :ordered_child_ids

  def name
    "#{object.author.first_name} #{object.author.last_name}"
  end

  def code
    object.author.code
  end

  def purpose
    object.purpose || 'Comment'
  end

  def parent_theme_ids
    # get the parent_theme_ids from the HABTM association
    object.parent_targets.map(&:parent_id).uniq
  end

  def ordered_child_ids
    # get the ordered_child_ids from the HABTM association
    object.child_targets.map(&:child_id).uniq
  end

  def editable_by_user
    ((defined? current_user).nil? || current_user.nil?) ? false : object.editable_by_user?(current_user)
  end

end
