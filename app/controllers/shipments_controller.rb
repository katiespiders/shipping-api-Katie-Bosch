
require 'active_shipping'
include ActiveMerchant::Shipping

class ShipmentsController < ApplicationController

  def show
    case carrier
    when 'USPS' then usps
    when 'FedEx' then fedex
    end

    rates
    render json: @rates
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
    # params[:carrier]
    'FedEx'
  end

  def packages
    # params[:packages]
    [
      Package.new(100,        # 100 grams
      [93,10],                # 93 cm long, 10 cm diameter
      :cylinder => true),     # cylinders have different volume calculations

      Package.new((7.5 * 16), # 7.5 lbs, times 16 oz/lb.
      [15, 10, 4.5],          # 15x10x4.5 inches
      :units => :imperial)    # not grams, not centimetres
    ]
  end

  def origin
    # params[:origin]
    Location.new(:country => 'US',
    :state => 'CA',
    :city => 'Beverly Hills',
    :zip => '90210')
  end

  def destination
    # params[:destination]
    Location.new(:country => 'CA',
    :province => 'ON',
    :city => 'Ottawa',
    :postal_code => 'K1P 1J1')
  end
end
