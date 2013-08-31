class TableCommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :type, :id, :order_id, :text, :updated_at, :purpose,
             :version, :number_of_votes, :tag_name, :tags,
             :editable_by_user, :name, :code, :published, :status

  def name
    if object.author.name_count.nil? || object.author.name_count  == 1
      "#{object.author.first_name}_#{object.author.last_name}"
    else
      "#{object.author.first_name}_#{object.author.last_name}_#{object.author.name_count}"
    end
  end

  def tags
    object.tags || []
  end

  def code
    object.author.code
  end

  def number_of_votes
    object.ratings_cache.inject{|sum,x| sum + x }
  end

  def purpose
    object.purpose || 'Comment'
  end

  def editable_by_user
    (defined?(current_user).nil? || current_user.nil?) ? false : object.editable_by_user?(current_user)
  end

end
