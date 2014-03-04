module Api
  module V1

    class AgendasController < Api::BaseController
      skip_authorization_check :only => [:agenda, :agenda_for_component, :accept_role, :release_role, :participant_report,
                                         :export, :import, :agendas, :participant_report_data, :data_set, :conversations,
                                         :reports, :report_data_sets, :agenda_defaults ]

      def agenda
        agenda = Agenda.find_by(code: params[:id])
        render json: agenda.agenda_data( current_user )
      end

      def agenda_for_component
        agenda = AgendaComponent.find_by(code: params[:id]).agenda
        render json: agenda.agenda_data( current_user )
      end


      def accept_role
        agenda = Agenda.find_by(code: params[:id])
        user = agenda.get_user_for_accept_role( params[:data] )
        sign_in(user)
        agenda_data = agenda.agenda_data( current_user )
        agenda_data[:user] = user.active_model_serializer.new(user).as_json
        respond_with agenda_data
      end

      def release_role
        agenda = Agenda.find_by(code: params[:id])
        agenda.release_role( current_user )
        sign_out(current_user) unless current_user.nil?
        render json: "Sign out successful"
      end

      def participant_report
        agenda = Agenda.find_by(code: params[:id])
        render json: agenda.participant_report
      end

      def participant_report_data
        agenda = Agenda.find_by(code: params[:id])
        render json: agenda.participant_report_data(params)
      end

      def export
        agenda = Agenda.find_by(code: params[:id])
        authorize! :export_agenda, agenda
        begin
          filename = "agenda-export-#{agenda.munged_title}.yaml"
          file = Tempfile.new(filename, 'tmp')
          # file.unlink   # removes the filesystem entry without closing the file
          agenda.export_to_file(file)
          send_file file.path, :filename => filename, :type => "text/yaml", disposition: 'attachment'
        ensure
          file.close
        end
      end

      def import
        #authorize! :import, Agenda
        # Eventually I want to upload the file, for now it will be in the Rails root
        filename = params[:filename]
        begin
          file = File.open( "#{Rails.root}/#{filename}" )

          code = Agenda.import(file)
        ensure
          begin
            file.close
          rescue
          end
        end

        #render :file => "#{Rails.root}/#{params[:filename]}"
        render text: "Import complete, code: #{code} for #{filename}"
      end

      def reset_agenda
        agenda = Agenda.find_by(code: params[:id])
        authorize! :reset_agenda, agenda
        agenda.reset
        render json: {Acknowledge: "Agenda \"#{agenda.title}\" has been reset"}
      end

      def agendas
        render json: Agenda.agendas
      end

      def data_set
        agenda = Agenda.find_by(code: params[:id])
        #authorize! :data_set, agenda
        render json: agenda.data_set(current_user, params[:link_code])
      end

      def conversations
        agenda = Agenda.find_by(code: params[:id])
        #authorize! :conversations, agenda
        render json: agenda.conversations
      end

      def reports
        agenda = Agenda.find_by(code: params[:id])
        #authorize! :reports, agenda
        render json: agenda.reports, :each_serializer => ReportListSerializer
      end

      def report_data_sets
        agenda = Agenda.find_by(code: params[:id])
        #authorize! :reports, agenda
        render json: agenda.report_data_sets
      end

      def agenda_admin_details
        agenda = Agenda.find_by(code: params[:id])
        authorize! :agenda_admin_details, agenda
        render json: agenda.agenda_admin_details
      end

      def refresh_agenda
        agenda = Agenda.find_by(code: params[:id])
        authorize! :refresh_agenda, agenda
        agenda.refresh_agenda_details_links_and_data_sets
        render json: {ack: "Agenda \"#{agenda.title}\" has been refreshed"}
      end

      def delete_agenda
        agenda = Agenda.find_by(code: params[:id])
        authorize! :delete_agenda, agenda
        agenda.delete_agenda
        render json: {ack: "Agenda \"#{agenda.title}\" has been deleted", action: 'reload'}
      end

      def create
        authorize! :create_agenda, Agenda
        render json: Agenda.create_agenda(params[:title])
      end

      def add_conversation
        agenda = Agenda.find_by(code: params[:id])
        authorize! :add_conversation, agenda
        render json: agenda.add_conversation(params[:title])
      end

      def update_agenda
        agenda = Agenda.find_by(code: params[:id])
        authorize! :update_agenda, agenda
        render json: agenda.update_agenda(params[:data])
      end

      def agenda_defaults
        render json: Agenda.agenda_defaults
      end

    end
  end
end
