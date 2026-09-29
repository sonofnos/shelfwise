module Api
  module V1
    class ProductsController < ApplicationController
      before_action :authorize_admin!, only: [ :create ]

      def index
        render json: Product.order(:sku).map { |p| product_json(p) }
      end

      def create
        product = Product.create!(product_params)
        render json: product_json(product), status: :created
      end

      private

      def product_params
        params.permit(:sku, :name, :price_cents)
      end

      def product_json(product)
        { id: product.id, sku: product.sku, name: product.name, price_cents: product.price_cents }
      end

      def authorize_admin!
        authorize_roles!(:admin)
      end
    end
  end
end
