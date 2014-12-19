require 'active_shipping'
include ActiveMerchant::Shipping

class ShipmentsController < ApplicationController

  def show
    case carrier
    when 'USPS' then usps
    when 'FedEx' then fedex
    end

    rates

    respond_to do |format|
      format.xml  { render xml: @rates}
      format.json { render json: @rates }
    end
  end

  private

    def fedex
      @carrier_obj = FedEx.new(login: ENV['FEDEX_LOGIN'], password: ENV['FEDEX_PW'], key: ENV['FEDEX_KEY'], account: ENV['FEDEX_ACCT'], test: true)
    end

    def usps
      @carrier_obj = USPS.new(login: ENV['USPS_KEY'])
    end

    def rates
      response = @carrier_obj.find_rates(origin, destination, packages)
      @rates = response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
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
      Location.new(params.require(:destination).permit(:country, :state, :city, :zip))
    end
end
