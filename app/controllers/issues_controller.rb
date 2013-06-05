class IssuesController < ApplicationController
  protect_from_forgery
  before_action :set_issue, only: [ :edit, :update, :destroy]

  #skip_before_filter :verify_authenticity_token, if: :json_request?

  def show
    if params[:issue_id]
      @issue = Issue.find( params[:issue_id] )
    elsif params[:munged_title]
      @issue = Issue.find_by_munged_title( params[:munged_title] )
    end
    not_found if @issue.nil?

    @issue_data = @issue.active_model_serializer.new(@issue, scope: { shallow_serialization_mode: true} )

    if current_user
      firebase_auth_data =    { userid: "#{current_user.id}",
                                issues_read: { "#{@issue.id}" => true },
                                issues_write: { "#{@issue.id}" => true }
                              }
      @firebase_token = Firebase::FirebaseTokenGenerator.new(Firebase.auth).create_token(firebase_auth_data)
    end

    render text: 'ok', layout: true
  end

  #def index
  #  respond_with Comment.all
  #end
  #
  #def create
  #  respond_with Comment.create( issue_params )
  #end
  #
  #def update
  #  respond_with Comment.update(params[:id], issue_params )
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

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_issue
    @issue = Issue.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def issue_params
    params.require(:issue).permit(:initiative_id, :user_id, :title, :description, :version, :status, :purpose, :munged_title)
  end

end
