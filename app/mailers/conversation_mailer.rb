class ConversationMailer < ActionMailer::Base

  self.default :from => "CivicEvolution <support@civicevolution.org>",
               :reply_to => "support@civicevolution.org"

  def host
    if Rails.env.development?
      "http://app.civicevolution.dev:8001"
    else
      "http://app.civicevolution.org"
    end
  end


  def publish_notification_curator( recip, conversation, mcode ='' )
    @recip=recip
    @conversation = conversation
    @mcode=mcode
    @host=host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Your CivicEvolution conversation has been published"
    )
  end

  def publish_notification_admin( curator, conversation, mcode ='' )
    @curator=curator
    @conversation = conversation
    @mcode=mcode
    @host=host

    mail(:to => "CivicEvolution <support@civicevolution.org>",
         :subject => "Another CivicEvolution conversation has been published"
    )
  end

  def immediate_notification(recip, post, mcode)
    @recip=recip
    @conversation = post.conversation
    @post = post
    @post_type = case @post.type
                   when "ConversationComment" then "comment"
                   when "SummaryComment" then "summary comment"
                   when "CallToActionComment" then "call-to-action"
                 end
    @author = case @post.type
                   when "ConversationComment" then "#{@post.author.first_name} #{@post.author.last_name}"
                   else "Conversation curator"
                 end

    @mcode=mcode
    @host=host
    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Someone just posted in your CivicEvolution conversation"
    )
  end


  def periodic_report(recip, conversation, summary_comments, conversation_comments, call_to_action_comment, report_time, mcode)
    @recip=recip
    @conversation = conversation
    @summary_comments = summary_comments
    @conversation_comments = conversation_comments
    @call_to_action_comment = call_to_action_comment
    @report_time = report_time
    @mcode = mcode
    @host = host
    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Daily report for #{@conversation.title}"
    )
  end

  def guest_post_accepted(recip, conversation, post, join_request=false, mcode ='' )
    @recip = recip
    @conversation = conversation
    @post = post
    @join_request = join_request
    @mcode = mcode
    @host = host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Your comment has been accepted"
    )
  end

  def guest_post_declined(recip, conversation, post, join_request=false, mcode ='' )
    @recip = recip
    @conversation = conversation
    @post = post
    @join_request = join_request
    @mcode = mcode
    @host = host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Sorry, your comment has been declined"
    )
  end

  def comment_accepted(recip, conversation, post, mcode ='' )
    @recip = recip
    @conversation = conversation
    @post = post
    @mcode = mcode
    @host = host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Your comment has been approved"
    )
  end

  def comment_declined(recip, conversation, post, mcode ='' )
    @recip = recip
    @conversation = conversation
    @post = post
    @mcode = mcode
    @host = host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Sorry, your comment has been declined"
    )
  end

  def send_invite(sender, recip_first, recip_last, recip_email, message, conversation, code )
    @sender = sender
    @recip_first = recip_first
    @message = message
    @conversation = conversation
    @host = host
    @invite_href = "#{@host}/invites/#{code}/#{@conversation.munged_title}"

    mail(:to => "#{recip_first} #{recip_last} <#{recip_email}>",
         :from => "#{sender.first_name} #{sender.last_name} <#{sender.email}>",
         :subject => "Please join our conversation \"#{conversation.title}"
    )
  end

  def send_guest_confirmation( recip_first, recip_last, recip_email, code )
    @recip_first = recip_first
    @host = host
    @confirmation_href = "#{@host}/guest_confirmation/#{code}"

    mail(:to => "#{recip_first} #{recip_last} <#{recip_email}>",
         :subject => "Please confirm your recent guest comment at CivicEvolution"
    )
  end

end