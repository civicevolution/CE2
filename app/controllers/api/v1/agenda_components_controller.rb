module Api
  module V1

    class AgendaComponentsController < Api::BaseController
      skip_authorization_check :only => [:data]

      def data
        component = AgendaComponent.find_by(code: params[:id])
        #authorize! :XXX, component.agenda
        Rails.logger.debug "Provide the data for this component"
        data = component.data(params[:conv_code])

        respond_with data
        #render json: data
      end

    end
  end
end
