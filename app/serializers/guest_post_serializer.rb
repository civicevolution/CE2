class GuestPostSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :first_name, :last_name, :email, :member_status, :text, :purpose,
             :reply_to_id, :reply_to_version, :request_to_join, :updated_at,
             :code, :invited_at


end
