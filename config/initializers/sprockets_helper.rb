module Sprockets
  module Helpers
    module RailsHelper

      def path_to_asset(asset)
        ApplicationController.helpers.path_to_asset( asset )
      end

    end
  end
end