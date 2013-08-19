class FlaggedCommentSerializer < ActiveModel::Serializer
  self.root = false

  attributes :flag_id, :flagger, :flagger_photo_code,
             :flagged_at, :flag_type, :flag_category, :flag_statement, :flagged_version,
             :author, :author_photo_code, :comment_text, :comment_purpose, :comment_version, :comment_posted_at


  def flag_id
    object.id
  end

  def flagger
    "#{object.flagger.first_name} #{object.flagger.last_name}"
  end

  def flagger_photo_code
    object.flagger.code
  end

  def flagged_at
    object.created_at
  end

  def flag_type
    object.target_type
  end

  def flag_category
    object.category
  end

  def flag_statement
    object.statement
  end

  def flagged_version
    object.version
  end

  def author
    "#{object.comment.author.first_name} #{object.comment.author.last_name}"
  end

  def author_photo_code
    object.comment.author.code
  end

  def comment_text
    object.comment.text
  end

  def comment_purpose
    object.comment.purpose
  end

  def comment_version
    object.comment.version
  end

  def comment_posted_at
    object.comment.updated_at
  end

end
