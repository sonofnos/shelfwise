module Api
  module V1
    class OrdersController < ApplicationController
      before_action :authorize_staff!

      def index
        render json: Order.includes(order_items: [ :product, :warehouse ]).order(created_at: :desc).map { |o| order_json(o) }
      end

      def create
        items = order_params[:items].map do |item|
          {
            product: Product.find(item[:product_id]),
            warehouse: Warehouse.find(item[:warehouse_id]),
            quantity: item[:quantity].to_i
          }
        end

        order = Order.place!(
          customer_name: order_params[:customer_name],
          customer_email: order_params[:customer_email],
          external_reference: order_params[:external_reference],
          items: items
        )

        render json: order_json(order), status: :created
      end

      def pay
        order = Order.find(params[:id])
        order.mark_paid!
        render json: order_json(order)
      end

      def ship
        order = Order.find(params[:id])
        order.ship!
        render json: order_json(order)
      end

      def cancel
        order = Order.find(params[:id])
        order.cancel!
        render json: order_json(order)
      end

      private

      def order_params
        params.permit(:customer_name, :customer_email, :external_reference, items: [ :product_id, :warehouse_id, :quantity ])
      end

      def order_json(order)
        {
          id: order.id,
          status: order.status,
          external_reference: order.external_reference,
          customer_name: order.customer_name,
          items: order.order_items.map do |line|
            { product: line.product.sku, warehouse: line.warehouse.code, quantity: line.quantity }
          end
        }
      end

      def authorize_staff!
        authorize_roles!(:admin, :staff)
      end
    end
  end
end
