module Api
  module V1

    class ReportsController < Api::BaseController
      skip_authorization_check :only => [:upload_report]

      def upload_report
        logger.debug "upload_report user_id: #{current_user.id}"

        report = Report.new
        report_links = report.populate_new_report(params, current_user)

        render json: report_links
      end

    end

  end
end
