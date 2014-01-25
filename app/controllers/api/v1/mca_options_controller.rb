module Api
  module V1
    class McaOptionsController < Api::BaseController
      skip_authorization_check only: [:project_assignments, :assign_project]

      def project_assignments
        option = McaOption.find(params[:id])
        evaluations = option.evaluations.includes(:user)
        #authorize! :edit_theme_comment, conversation
        data = {
          title: option.title,
          id: option.id
        }
        evals = []
        evaluations.each do |evaluation|
          if evaluation.status != 'deleted'
            evals.push(
              {
                id: evaluation.id,
                name: "#{evaluation.user.first_name} #{evaluation.user.last_name}",
                user_id: evaluation.user.id
              }
            )
          end
        end
        data[:evaluators] = evals
        participants = []
        option.multi_criteria_analysis.agenda.participants.select{|u| u.email.match(/group/)}.sort{|a,b| a.id <=> b.id}.each do |u|
          participants.push( {user_id: u.id, name: "#{u.first_name} #{u.last_name}" }) unless u.last_name.to_i > 7
        end
        data[:participants] = participants
        render json: data
      end

      def assign_project
        option = McaOption.find(params[:id])
        #authorize! :edit_theme_comment, conversation
        evaluation = option.add_evaluation( { user_id: [ params[:user_id] ], category: 'group' })
        evaluation.realtime_notification
        render json: {add_evalution: 'ok', option_id: option.id, user_id: params[:user_id] }
      end

    end
  end
end