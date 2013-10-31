module Api
  module V1

    class ReportsController < Api::BaseController
      skip_authorization_check :only => [:upload_report, :destroy, :show]

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

    end

  end
end
