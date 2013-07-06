class IssueSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :title, :description, :version, :initiative_id, :created_at, :updated_at, :munged_title, :current_timestamp
  has_many :questions
  has_one :initiative

  def include_questions?
    !( scope && scope[:list_issues_only_mode] )
  end

  def include_initiative?
    !( scope && scope[:list_issues_only_mode] )
  end


  def current_timestamp
    Time.new.to_i
  end



end
