class IssuesController < ApplicationController
  protect_from_forgery
  #skip_before_filter :verify_authenticity_token, if: :json_request?

  def show
    if params[:issue_id]
      @issue = Issue.find( params[:issue_id] )
    elsif params[:munged_title]
      @issue = Issue.find_by_munged_title( params[:munged_title] )
    end
    not_found if @issue.nil?
  end

  #def index
  #  respond_with Comment.all
  #end
  #
  #def create
  #  respond_with Comment.create(params[:comment])
  #end
  #
  #def update
  #  respond_with Comment.update(params[:id], params[:comment])
  #end
  #
  #def destroy
  #  respond_with Comment.destroy(params[:id])
  #end
  #
  #protected
  #
  #def json_request?
  #  request.format.json?
  #end

end
