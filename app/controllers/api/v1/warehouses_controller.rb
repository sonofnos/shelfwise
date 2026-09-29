module Api
  module V1
    class WarehousesController < ApplicationController
      def index
        render json: Warehouse.order(:code).map { |w| { id: w.id, name: w.name, code: w.code } }
      end
    end
  end
end
