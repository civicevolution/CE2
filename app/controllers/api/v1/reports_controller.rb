module Api
  module V1
    class ReportsController < Api::BaseController

      skip_authorization_check :only => [:upload_report, :destroy, :show, :show_comments, :criteria_stats, :results_graph, :show_key_themes, :options_review_report]

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

        # or from your controller, using views & templates and all wicked_pdf options as normal
        pdf_save_name = "#{@conversation.munged_title.gsub('&','')}-suggestions.pdf"
        pdf = render_to_string pdf:"#{pdf_save_name}",
                               template: 'reports/show-comments.html.haml',
                               layout: 'pdf-report',
                               disposition: 'attachment',
                               wkhtmltopdf: '/usr/local/bin/wkhtmltopdf',
                               show_as_html: params[:debug].present?,
                               dpi: 300,
                               page_size: 'letter',
                               margin: { top: 0,
                                         bottom: 0,
                                         left:0,
                                         right: 0
                               }

        files = []
        pdf_save_path = "./public/#{pdf_save_name}"
        File.open(pdf_save_path, 'wb') do |file|
          file << pdf
        end
        files.push( pdf_save_name )

        begin
          cmd = "identify #{pdf_save_path}"
          num_pages = `#{cmd}`.split(/\n/).size

          Rails.logger.debug "Create num_pages: #{num_pages} jpgs from this pdf: #{pdf_save_path}"

          (0...num_pages).each do |page_num|
            jpg_save_name = pdf_save_name.sub(/pdf$/,"#{page_num}.jpg")
            jpg_save_path = "./public/#{jpg_save_name}"
            Rails.logger.debug "jpg_save_path: #{jpg_save_path} for page: #{page_num}"
            #pdf[page_num].write(jpg_save_path)
            cmd = "convert #{pdf_save_path}[#{page_num}] #{jpg_save_path}"
            Rails.logger.debug "cmd: #{cmd}"
            `#{cmd}`
            files.push( jpg_save_name )
          end
        rescue Exception => e
          Rails.logger.warn "^^^^^^^ XXXXXX  show_comments convert pdf to jpg error: #{e}"
        end

        render json: files

      end


      def show_key_themes
        Rails.logger.debug "show_key_themes agenda_code: #{params[:agenda_code]}, conversation_code: #{params[:conversation_code]}"

        @theme_data = ThemeSmallGroupTheme.data_key_themes_with_examples( {"conversation_code" => params[:conversation_code],
           "coordinator_user_id" => Agenda.find_by(code: params[:agenda_code]).details['coordinator_user_id']} )
        @conversation = Conversation.find_by(code: params[:conversation_code] )

        pdf_save_name = "#{@conversation.munged_title.gsub('&','')}-key-themes.pdf"

        pdf = render_to_string  pdf:"#{pdf_save_name}",
                                template: 'reports/show-key-themes.html.haml',
                                layout: 'pdf-report',
                                disposition: 'attachment',
                                wkhtmltopdf: '/usr/local/bin/wkhtmltopdf',
                                show_as_html: params[:debug].present?,
                                dpi: 300,
                                page_size: 'A4',
                                margin: { top: 0,
                                          bottom: 0,
                                          left:0,
                                          right: 0
                                }
        files = []
        pdf_save_path = "./public/#{pdf_save_name}"
        File.open(pdf_save_path, 'wb') do |file|
          file << pdf
        end
        files.push( pdf_save_name )

        begin
          cmd = "identify #{pdf_save_path}"
          num_pages = `#{cmd}`.split(/\n/).size

          Rails.logger.debug "Create num_pages: #{num_pages} jpgs from this pdf: #{pdf_save_path}"

          (0...num_pages).each do |page_num|
            jpg_save_name = pdf_save_name.sub(/pdf$/,"#{page_num}.jpg")
            jpg_save_path = "./public/#{jpg_save_name}"
            Rails.logger.debug "jpg_save_path: #{jpg_save_path} for page: #{page_num}"
            #pdf[page_num].write(jpg_save_path)
            cmd = "convert #{pdf_save_path}[#{page_num}] #{jpg_save_path}"
            Rails.logger.debug "cmd: #{cmd}"
            `#{cmd}`
            files.push( jpg_save_name )
          end
        rescue Exception => e
          Rails.logger.warn "^^^^^^^ XXXXXX  key_themes convert pdf to jpg error: #{e}"
        end
        render json: files
      end


      def results_graph
        Rails.logger.debug "results_graph agenda_code: #{params[:agenda_code]}, conversation_code: #{params[:conversation_code]}"

        @conversation = Conversation.find_by(code: params[:conversation_code] )

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

        pdf_save_name = "#{@conversation.munged_title.gsub('&','')}-results-graph.pdf"
        pdf = render_to_string  pdf:"#{pdf_save_name}",
                                template: 'reports/show-results.html.haml',
                                layout: 'pdf-report',
                                disposition: 'attachment',
                                wkhtmltopdf: '/usr/local/bin/wkhtmltopdf',
                                show_as_html: params[:debug].present?,
                                dpi: 300,
                                page_size: 'A4',
                                margin: { top: 0,
                                          bottom: 0,
                                          left:0,
                                          right: 0
                                }

        files = []
        pdf_save_path = "./public/#{pdf_save_name}"
        File.open(pdf_save_path, 'wb') do |file|
          file << pdf
        end
        files.push( pdf_save_name )

        begin
          cmd = "identify #{pdf_save_path}"
          num_pages = `#{cmd}`.split(/\n/).size

          Rails.logger.debug "Create num_pages: #{num_pages} jpgs from this pdf: #{pdf_save_path}"

          (0...num_pages).each do |page_num|
            jpg_save_name = pdf_save_name.sub(/pdf$/,"#{page_num}.jpg")
            jpg_save_path = "./public/#{jpg_save_name}"
            Rails.logger.debug "jpg_save_path: #{jpg_save_path} for page: #{page_num}"
            #pdf[page_num].write(jpg_save_path)
            cmd = "convert #{pdf_save_path}[#{page_num}] #{jpg_save_path}"
            Rails.logger.debug "cmd: #{cmd}"
            `#{cmd}`
            files.push( jpg_save_name )
          end
        rescue Exception => e
          Rails.logger.warn "^^^^^^^ XXXXXX  show_comments convert pdf to jpg error: #{e}"
        end

        render json: files
      end

      def criteria_stats
        agenda = Agenda.find_by(code: params[:agenda_code])
        @totals, @conversation_stats = agenda.criteria_stats
        render template: 'reports/agenda-criteria-stats', layout: 'pdf-report'
      end

      def options_review_report
        agenda = Agenda.find_by(code: params[:agenda_code])
        mca = agenda.mca[0]
        data = mca.detailed_report


        @report = []
        data['options'].each do |service|

          service_recommendations_hash = {}
          (service[:data].try{|data| data['service_recommendations'] } || []).each do |service_recommendation|
            budget_dir_id = service_recommendation['budget_dir_id']
            service_recommendations_hash[budget_dir_id] = [] unless service_recommendations_hash[budget_dir_id]
            service_recommendations_hash[budget_dir_id].push( service_recommendation )
          end

          service_suggestions_hash = {}
          (service[:data].try{|data| data['service_suggestions'] } || []).each do |service_suggestion|
            budget_dir_id = service_suggestion['budget_dir_id']
            service_suggestions_hash[budget_dir_id] = [] unless service_suggestions_hash[budget_dir_id]
            service_suggestions_hash[budget_dir_id].push( service_suggestion )
          end


          (service[:data].try{|data| data['service_level_recommendations']} || [ {} ]).each do |level|
            actions = service_recommendations_hash[level['_id']] || [  ]
            actions.each do |action|
              row = {
                service_id: service[:id],
                service_title: service[:title],
                category: service[:category],
                level: level['service_level_recommendation'],
                specific_action: { form: action['form'], increase: action['increase'], decrease: action['decrease'], reason: action['reason']},
                suggestion: {}
              }
              @report.push(row)
            end

            suggestions = service_suggestions_hash[level['_id']] || [  ]
            suggestions.each do |suggestion|
              row = {
                service_id: service[:id],
                service_title: service[:title],
                category: service[:category],
                level: level['service_level_recommendation'],
                specific_action: {},
                suggestion: { form: suggestion['form'], text: suggestion['text']}
              }
              @report.push(row)
            end

            if actions.length == 0 && suggestions.length == 0
              row = {
                service_id: service[:id],
                service_title: service[:title],
                category: service[:category],
                level: level['service_level_recommendation'],
                specific_action: {},
                suggestion: {}
              }
              @report.push(row)
            end
          end
        end

        # iterate through the report table and mark Service and direction "As above" when they repeat
        service = ''
        level = ''
        @report.each do |row|
          if service != row[:service_title]
            service = row[:service_title]
            row[:title] = service
            row[:cat] = row[:category]
            level = ''
          else
            row[:title] = 'As above'
            row[:cat] = ''
          end

          if level != row[:level]
            level = row[:level]
            row[:level_r] = level
          else
            row[:level_r] = 'As above'
          end
        end

        render template: 'reports/options-review-report', layout: 'pdf-report'
      end

    end

  end
end