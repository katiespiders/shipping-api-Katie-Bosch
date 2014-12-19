require 'active_shipping'
include ActiveMerchant::Shipping

class ShipmentsController < ApplicationController

  def show
    begin
      Timeout::timeout(15) { display_rates }
    rescue Timeout::Error
      render json: {error: timeout_error}, status: :request_timeout
    end
  end

  private

    def display_rates
      case carrier
      when 'USPS' then usps
      when 'FedEx' then fedex
      end

      rates
    end

    def fedex
      @carrier_obj = FedEx.new(login: ENV['FEDEX_LOGIN'], password: ENV['FEDEX_PW'], key: ENV['FEDEX_KEY'], account: ENV['FEDEX_ACCT'], test: true)
    end

    def usps
      @carrier_obj = USPS.new(login: ENV['USPS_KEY'])
    end

    def rates
      if valid_address?
        rates_array
        respond_to do |format|
          format.xml  { render xml: rates_array, status: :ok}
          format.json { render json: rates_array, status: :ok }
        end
      else
        render json: {error: incomplete_error}, status: :bad_request
      end
    end

    def rates_array
      response = @carrier_obj.find_rates(origin, destination, packages)
      response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
    end

    def carrier
      params[:carrier]
    end

    def packages
      packages_hash, packages_array = params[:packages], []
      packages_hash.each do |index, package|
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
      "Timed out; this is either FedEx's or USPS's fault."
    end

    def incomplete_error
      "Destination address is incomplete"
    end
end
