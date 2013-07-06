class InitiativeSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :title, :description, :created_at, :updated_at, :munged_title, :current_timestamp
  has_many :issues

  def include_issues?
    scope && scope[:list_issues_only_mode]
  end

  def current_timestamp
    Time.new.to_i
  end

end