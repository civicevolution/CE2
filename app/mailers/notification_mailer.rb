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


  #def periodic_report(recip, app, teams, ideas, comments, reports, mcode,sent_at = Time.now)
  #  @recip=recip
  #  @teams=teams
  #  @ideas = ideas
  #  @comments = comments
  #  @reports = reports
  #  @mcode = mcode
  #  mail(:to => "#{recip.first_name} #{recip.last_name} <#{recip.email}>",
  #       :subject => "Your #{app} CivicEvolution proposal has been updated",
  #       :from => "#{app} at CivicEvolution <support@civicevolution.org>",
  #       :date => sent_at
  #  )
  #end




end