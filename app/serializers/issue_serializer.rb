class IssueSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :title, :description, :version, :created_at, :updated_at, :munged_title, :current_timestamp
  has_many :questions

  def include_questions?
    !( scope && scope[:list_issues_only_mode] )
  end

  def current_timestamp
    Time.new.to_i
  end

end
