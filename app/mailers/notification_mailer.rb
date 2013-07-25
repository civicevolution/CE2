class NotificationMailer < ActionMailer::Base

  def immediate(recip, post, mcode, host)
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
         :subject => "Someone just posted in your CivicEvolution conversation",
         :from => "CivicEvolution <support@civicevolution.org>"
    )
  end


  def periodic(recip, conversation, summary_comments, conversation_comments, call_to_action_comment, report_time, mcode, host)
    @recip=recip
    @conversation = conversation
    @summary_comments = summary_comments
    @conversation_comments = conversation_comments
    @call_to_action_comment = call_to_action_comment
    @report_time = report_time
    @mcode = mcode
    @host = host
    mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
         :subject => "Daily report for #{@conversation.title}",
         :from => "CivicEvolution <support@civicevolution.org>",
         :from => "CivicEvolution <support@civicevolution.org>"
    )
  end




end