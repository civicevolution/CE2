class InvitedGuestSerializer < ActiveModel::Serializer
  #embed :ids, :include => true
  attributes :invitee, :invited_at, :inviter

  def invitee
    "#{object.first_name} #{object.last_name}"
  end

  def invited_at
    object.created_at
  end

  def inviter
    "#{object.sender.first_name} #{object.sender.last_name}"
  end


end
