module StripeMock
  module RequestHandlers
    module Prices
      ALLOWED_UPDATE_PARAMS = [
        :active,
        :metadata,
        :nickname,
        :lookup_key,
        :transfer_lookup_key,
      ]

      def self.included(klass)
        klass.add_handler 'post /v1/prices',               :new_price
        klass.add_handler 'get /v1/prices',                :get_prices
        klass.add_handler 'get /v1/prices/(.*)',           :get_price
        klass.add_handler 'post /v1/prices/(.*)',          :update_price
      end

      def new_price(_route, _method_url, params, _headers)
        id = new_id('price')

        prices[id] = Data.mock_price(params.merge(id: id))

        if params[:currency].blank?
          raise Stripe::InvalidRequestError.new('You must pass a currency', 'currency', http_status: 400)
        end

        if params[:billing_scheme].blank? && params[:unit_amount].blank?
          raise Stripe::InvalidRequestError.new(
            'You must pass either a billing_scheme or unit_amount',
            'unit_amount',
            http_status: 400
          )
        end

        if params[:billing_scheme] == 'tiered' && (params[:tiers].blank? || params[:tiers_mode].blank?)
          raise Stripe::InvalidRequestError.new(
            'You must pass both tiers and tiers_mode when using a tiered billing_scheme',
            'billing_scheme',
            http_status: 400
          )
        end

        price[id].clone
      end

      def update_price(route, method_url, params, _headers)
        route =~ method_url
        id = Regexp.last_match(1)

        price = assert_existence :price, id, prices[id]
        prices[id] = Util.rmerge(price, params.select{ |k, _v| ALLOWED_UPDATE_PARAMS.include?(k)})
      end

      def get_prices(_route, _method_url, params, _headers)
        params[:limit] ||= 10

        Data.mock_list_object(prices.clone, params)
      end

      def get_price(route, method_url, params, _headers)
        route =~ method_url
        price_id = Regexp.last_match(1) || params[:price]
        price = assert_existence :price, price_id, prices[price_id]

        price.clone
      end
    end
  end
end
