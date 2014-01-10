class ConversationThemeDataSerializer < ActiveModel::Serializer
  attributes :updated_at, :code, :title, :munged_title,
             :current_timestamp, :privacy, :published, :starts_at, :ends_at, :role
  has_many :theme_and_table_comments

  def theme_and_table_comments
    object.theme_page_comments.select{|c| c.type == 'ThemeComment' || c.type == 'TableComment'}
  end

  def munged_title
    object.theme_page_comments.detect{|c| c.type == 'TitleComment'}.try{ |title_comment| title_comment.text.gsub(/\s/, "-").gsub(/[^\w&-]/,'').downcase[0..50]}
  end

  def title
    object.theme_page_comments.detect{|c| c.type == 'TitleComment'}.try{ |title_comment| title_comment.text}
  end

  def current_timestamp
    Time.new.to_i
  end

  def role
    Ability.abilities(current_user, 'Conversation', object.id)
  end

end
