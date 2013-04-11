class CommentsController < ApplicationController
  protect_from_forgery
  skip_before_filter :verify_authenticity_token, if: :json_request?
  
  respond_to :json
  
  def index
    respond_with Comment.all
  end

  def show
    respond_with Comment.find(params[:id])
  end

  def create
    respond_with Comment.create(params[:comment])
  end

  def update
    respond_with Comment.update(params[:id], params[:comment])
  end

  def destroy
    respond_with Comment.destroy(params[:id])
  end

  protected

  def json_request?
    request.format.json?
  end

end
