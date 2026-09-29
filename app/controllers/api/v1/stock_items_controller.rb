module Api
  module V1
    class StockItemsController < ApplicationController
      def index
        scope = StockItem.includes(:product, :warehouse)
        scope = scope.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
        render json: scope.map { |s| stock_item_json(s) }
      end

      private

      def stock_item_json(item)
        {
          id: item.id,
          product: { id: item.product.id, sku: item.product.sku, name: item.product.name },
          warehouse: { id: item.warehouse.id, code: item.warehouse.code },
          quantity_on_hand: item.quantity_on_hand,
          quantity_reserved: item.quantity_reserved,
          available: item.available
        }
      end
    end
  end
end
