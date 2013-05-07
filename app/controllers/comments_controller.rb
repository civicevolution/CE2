class CommentsController < ApplicationController
  protect_from_forgery
  before_action :set_comment, only: [:show, :edit, :update, :destroy]
  skip_before_filter :verify_authenticity_token, if: :json_request?
  
  respond_to :json
  
  def index
    respond_with Comment.all
  end

  def show
    respond_with Comment.find(params[:id])
  end

  def create
    respond_with Comment.create(comment_params)
  end

  def update
    respond_with Comment.update(params[:id], comment_params)
  end

  def destroy
    respond_with Comment.destroy(params[:id])
  end

  protected

  def json_request?
    request.format.json?
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_comment
    @comment = Comment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def comment_params
    params.require(:comment).permit(:conversation_id, :text, :version, :status, :order_id, :purpose, :references,)
  end

end
