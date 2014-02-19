module Api
  module V1

    class ReportsController < Api::BaseController
      skip_authorization_check :only => [:upload_report, :destroy, :show, :show_comments, :criteria_stats]

      def upload_report
        logger.debug "upload_report user_id: #{current_user.id}"

        report = Report.new
        report_links = report.populate_new_report(params, current_user)

        render json: report_links
      end

      def show
        report = Report.find(params[:id])
        render json: report.as_json
      end

      def destroy
        report = Report.find(params[:id])
        report.destroy
        render json: {report_destroyed_id: report.id}
      end

      def show_comments
        Rails.logger.debug "agenda_code: #{params[:agenda_code]}, conversation_code: #{params[:conversation_code]}"

        @conversation =Conversation.find_by(code: params[:conversation_code] )

        #render template: 'reports/show-comments', layout: 'pdf-report'

        respond_to do |format|
          format.html {render template: 'reports/show-comments', layout: 'pdf-report'}
          format.pdf do
            render :pdf => "show-comments.pdf",
            template: 'reports/show-comments.html.haml',
            layout: 'pdf-report',
            wkhtmltopdf: '/usr/local/bin/wkhtmltopdf'
          end
        end


      end

      def criteria_stats
        agenda = Agenda.find_by(code: params[:agenda_code])
        @totals, @conversation_stats = agenda.criteria_stats
        render template: 'reports/agenda-criteria-stats', layout: 'pdf-report'
      end

    end

  end
end