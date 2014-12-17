
require 'active_shipping'
include ActiveMerchant::Shipping

class ShipmentsController < ApplicationController

  def show
    @shipment = case shipment_params[:carrier]
    when 'USPS'
      usps = USPS.new(login: ENV['USPS_KEY'])
      response = usps.find_rates(shipment_params[:origin], shipment_params[:destination], shipment_params[:packages])
      @rates = response.rates.sort_by(&:price).collect {|rate| [rate.service_name, rate.price]}
    end
    render json: @rates
  end

  private


  def shipment_params
    {
      carrier: 'USPS',
      packages:
      [
        Package.new(100,        # 100 grams
        [93,10],                # 93 cm long, 10 cm diameter
        :cylinder => true),     # cylinders have different volume calculations

        Package.new((7.5 * 16), # 7.5 lbs, times 16 oz/lb.
        [15, 10, 4.5],          # 15x10x4.5 inches
        :units => :imperial)    # not grams, not centimetres
      ],
      origin:
      Location.new(:country => 'US',
      :state => 'CA',
      :city => 'Beverly Hills',
      :zip => '90210'),
      destination:
      Location.new(:country => 'CA',
      :province => 'ON',
      :city => 'Ottawa',
      :postal_code => 'K1P 1J1')
    }
  end

end
