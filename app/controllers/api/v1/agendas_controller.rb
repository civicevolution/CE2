module Api
  module V1

    class AgendasController < Api::BaseController
      skip_authorization_check :only => [:agenda, :agenda_for_component, :accept_role, :release_role, :role_menu_data, :participant_report, :export, :import]

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

      def role_menu_data
        agenda = Agenda.find_by(code: params[:id])
        render json: agenda.role_menu_data( current_user )
      end

      def participant_report
        agenda = Agenda.find_by(code: params[:id])
        render json: agenda.participant_report
      end

      def export
        #authorize! :export, Agenda
        agenda = Agenda.find_by(code: params[:id])
        begin
          filename = "agenda-export-#{agenda.munged_title}.yaml"
          file = Tempfile.new(filename, 'tmp')
          # file.unlink   # removes the filesystem entry without closing the file
          agenda.export_to_file(file)
          send_file file.path, :filename => filename, :type => "x-yaml"
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

          Agenda.import(file)
        ensure
          file.close
        end

        #render :file => "#{Rails.root}/#{params[:filename]}"
        render text: "Import of #{filename} is complete"
      end

    end
  end
end
