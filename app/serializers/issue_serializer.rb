class IssueSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :title, :description, :version, :created_at, :updated_at, :munged_title
  has_many :questions

end
