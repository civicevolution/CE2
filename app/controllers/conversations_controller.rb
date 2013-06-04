class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :edit, :update, :destroy]

  def index
    Rails.logger.debug "Conversation#index"
  end



  private
  # Use callbacks to share common setup or constraints between actions.
  def set_conversation
    @issue = Conversation.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def conversation_params
    params.require(:conversation).permit( :question_id, :status )
  end




end
