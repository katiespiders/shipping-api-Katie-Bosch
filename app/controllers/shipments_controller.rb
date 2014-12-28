require 'active_shipping'
include ActiveMerchant::Shipping

class ShipmentsController < ApplicationController

  def show
    call_api_with_timeout
  end

  private

    def call_api_with_timeout
      begin
        Timeout::timeout(10) {
          case carrier
          when "USPS"
            call_usps
            log_request
          when "FedEx"
            call_fedex
            log_request
          end
        }
        get_rates

      rescue Timeout::Error
        render json: [timeout_error], status: :request_timeout
        log_request
      end
    end

    def log_request
      Log.create(
        status: status,
        params: params.to_json,
        from: request.remote_host
      )
    end

    def call_fedex
      @carrier_obj = FedEx.new(login: ENV['FEDEX_LOGIN'], password: ENV['FEDEX_PW'], key: ENV['FEDEX_KEY'], account: ENV['FEDEX_ACCT'], test: true)
      puts "MADE FEDEX OBJECT"
    end

    def call_usps
      @carrier_obj = USPS.new(login: ENV['USPS_KEY'])
      puts "MADE USPS OBJECT"
    end

    def get_rates
      if valid_address?
        respond_to do |format|
          puts "GETTING RATES"
          format.xml  { render xml: rates_array, status: :ok}
          format.json { render json: rates_array, status: :ok }
        end
      else
        render json: [incomplete_error], status: :bad_request
        log_request
      end
    end

    def rates_array
      response = @carrier_obj.find_rates(origin, destination, packages)
      puts "RESPONSE IS A #{response.class.upcase}: #{response.inspect}"
      #response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
    end

    def carrier
      params[:carrier]
    end

    def packages
      puts "PARAMS KEYS ARE #{params.keys}"
      packages_array = []
      params[:packages].each do |index, package|
        weight = package[:weight].to_i
        dimensions = package[:dimensions].collect {|d| d.to_i}
        packages_array << Package.new(weight, dimensions)
      end
      packages_array
    end

    def origin
      Location.new( {
        country: 'US',
        state: 'WA',
        city: 'Seattle',
        zip: '98103'
      })
    end

    def destination
      Location.new(destination_params)
    end

    def valid_address?
      !destination_params.has_value?(nil)
    end

    def destination_params
      params.require(:destination).permit(:country, :state, :city, :zip)
    end

    def timeout_error
      "#{carrier}'s API timed out. Blame them.".html_safe
    end

    def incomplete_error
      "Destination address is incomplete."
    end
end
