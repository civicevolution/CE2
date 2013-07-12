module Api
  module V1

    class InitiativesController < Api::BaseController
      #load_and_authorize_resource

      def issues
        if params[:id] =~ /\A\d*\z/
          initiative = Initiative.find(params[:id])
        else
          initiative = Initiative.where(munged_title: params[:id]).first
        end

        respond_with initiative, scope: { list_issues_only_mode: true}
      end

    end

  end
end
