class ThemeCommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :updated_at, :purpose,
             :version, :tag_name,
             :editable_by_user, :name, :code, :published, :status,
             :bookmark, :ordered_child_ids

  def name
    if object.author.name_count.nil? || object.author.name_count  == 1
      "#{object.author.first_name}_#{object.author.last_name}"
    else
      "#{object.author.first_name}_#{object.author.last_name}_#{object.author.name_count}"
    end
  end

  def code
    object.author.code
  end

  def purpose
    object.purpose || 'Comment'
  end

  def ordered_child_ids
    # get the ordered_child_ids from the HABTM association
    object.child_targets.map(&:child_id)
  end

  def editable_by_user
    ((defined? current_user).nil? || current_user.nil?) ? false : object.editable_by_user?(current_user)
  end

end
