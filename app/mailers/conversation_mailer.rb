class ConversationMailer < ActionMailer::Base

  self.default :from => "CivicEvolution <support@civicevolution.org>",
               :reply_to => "support@civicevolution.org"


  def publish_notification_curator( recip, conversation, mcode ='', host = '' )
    @recip=recip
    @conversation = conversation
    @mcode=mcode
    @host=host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Your CivicEvolution conversation has been published"
    )
  end

  def publish_notification_admin( curator, conversation, mcode ='', host = '' )
    @curator=curator
    @conversation = conversation
    @mcode=mcode
    @host=host

    mail(:to => "CivicEvolution <support@civicevolution.org>",
         :subject => "Another CivicEvolution conversation has been published"
    )
  end

  def immediate_notification(recip, post, mcode, host)
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


  def periodic_report(recip, conversation, summary_comments, conversation_comments, call_to_action_comment, report_time, mcode, host)
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

  def guest_post_accepted(recip, conversation, post, mcode ='', host = '' )
    @recip = recip
    @conversation = conversation
    @post = post
    @mcode = mcode
    @host = host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Your comment has been accepted"
    )
  end

  def guest_post_declined(recip, conversation, post, mcode ='', host = '' )
    @recip = recip
    @conversation = conversation
    @post = post
    @mcode = mcode
    @host = host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Sorry, your comment has been declined"
    )
  end

  def comment_accepted(recip, conversation, post, mcode ='', host = '' )
    @recip = recip
    @conversation = conversation
    @post = post
    @mcode = mcode
    @host = host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Your comment has been approved"
    )
  end

  def comment_declined(recip, conversation, post, mcode ='', host = '' )
    @recip = recip
    @conversation = conversation
    @post = post
    @mcode = mcode
    @host = host

    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Sorry, your comment has been declined"
    )
  end

end