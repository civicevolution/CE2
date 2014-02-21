module Api
  module V1

    class ReportsController < Api::BaseController
      skip_authorization_check :only => [:upload_report, :destroy, :show, :show_comments, :criteria_stats, :results_graph, :show_key_themes]

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
        Rails.logger.debug "show_comments agenda_code: #{params[:agenda_code]}, conversation_code: #{params[:conversation_code]}"

        @conversation = Conversation.find_by(code: params[:conversation_code] )

        @additional_suggestions = nil
        Agenda.find_by(code: params[:agenda_code]).details['conversation_ids'].each do |ids|
          if ids.is_a?(Array) && ids.include?(@conversation.id)
            ids.delete(@conversation.id)
            if ids.length > 0
              @additional_suggestions = Conversation.find(ids[0])
            end
          end
        end

        respond_to do |format|
          format.html {render template: 'reports/show-comments', layout: 'pdf-report'}
          format.pdf do
            render  pdf:"show-comments.pdf",
                    template: 'reports/show-comments.html.haml',
                    layout: 'pdf-report',
                    wkhtmltopdf: '/usr/local/bin/wkhtmltopdf',
                    show_as_html: params[:debug].present?,
                    dpi: 300,
                    page_size: 'A4',
                    margin: { top: 0,
                              bottom: 0,
                              left:0,
                              right: 0
                            }
          end
        end
      end


      def show_key_themes
        Rails.logger.debug "show_key_themes agenda_code: #{params[:agenda_code]}, conversation_code: #{params[:conversation_code]}"

        @theme_data = ThemeSmallGroupTheme.data_key_themes_with_examples( {"conversation_code" => params[:conversation_code],
           "coordinator_user_id" => Agenda.find_by(code: params[:agenda_code]).details['coordinator_user_id']} )
        @conversation = Conversation.find_by(code: params[:conversation_code] )

        respond_to do |format|
          format.html {render template: 'reports/show-comments', layout: 'pdf-report'}
          format.pdf do
            render  pdf:"show-comments.pdf",
                    template: 'reports/show-key-themes.html.haml',
                    layout: 'pdf-report',
                    wkhtmltopdf: '/usr/local/bin/wkhtmltopdf',
                    show_as_html: params[:debug].present?,
                    dpi: 300,
                    page_size: 'A4',
                    margin: { top: 0,
                              bottom: 0,
                              left:0,
                              right: 0
                    }
          end
        end
      end


      def results_graph
        Rails.logger.debug "results_graph agenda_code: #{params[:agenda_code]}, conversation_code: #{params[:conversation_code]}"

        results = ConversationRecommendation.data_recommendation_results({'conversation_code'=> params[:conversation_code] })
        @title = results[:title]
        @vote_options = results[:vote_options]
        @table_votes = results[:table_votes]

        keys = {}
        @table_votes.each_key{ |key| keys[ key.match(/g(\d+)/)[1] ] = 1 }
        @tables = []
        keys.each_key{|key| @tables.push key}
        @tables.sort!

        @table_size = [ 3, 5, 4, 3, 4, 5, 4, 4]
        @sums = [0,0,0,0,0,0,0,0]
        @diffs = []
        @table_votes.each_pair do |key,value|
          group = key.match(/g(\d)/)[1].to_i
          @sums[ group - 1 ] += value
        end

        respond_to do |format|
          format.html {render template: 'reports/show-results', layout: 'pdf-report'}
          format.pdf do
            render :pdf => "show-results.pdf",
                   template: 'reports/show-results.html.haml',
                   layout: 'pdf-report',
                   wkhtmltopdf: '/usr/local/bin/wkhtmltopdf',
                   show_as_html: params[:debug].present?,
                   dpi: 300,
                   page_size: 'A4',
                    margin: { top: 0,
                              bottom: 0,
                              left:0,
                              right: 0
                            }
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