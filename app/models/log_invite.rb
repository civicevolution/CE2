class LogInvite < ActiveRecord::Base

  def self.log invite, user, details
    log = LogInvite.new
    invite.attributes.each_pair do |key,value|
      case key
        when "id", "updated_at"
        when "created_at"
          log.invited_at = value
        else
          log[key] = value
      end
    end
    log.user_id = user.id
    log.details = details
    log.save
  end

end
