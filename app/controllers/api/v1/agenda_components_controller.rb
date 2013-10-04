module Api
  module V1

    class AgendaComponentsController < Api::BaseController
      skip_authorization_check :only => [:data, :results]

      def data
        component = AgendaComponent.find_by(code: params[:id])
        #authorize! :XXX, component.agenda
        data = component.data(params, current_user)

        respond_with data
      end

      def results
        component = AgendaComponent.find_by(code: params[:id])
        #authorize! :XXX, component.agenda
        results = component.results(params, current_user)
        respond_with results
      end

    end
  end
end
