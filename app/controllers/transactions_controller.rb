require 'httparty'

class TransactionsController < ApplicationController
  def index
    Transaction.delete_all
    url = "https://www.buda.com/api/v2/"
    response = HTTParty.get(url+"markets.json")
    if response.code==200
      puts "worked"
    else
      puts "didn't work"
      
    end
    markets = response["markets"].map{ |market| market["id"]}
    currentTime = DateTime.now()
    trades_per_market = markets.map{ |market| HTTParty.get(url+"markets/#{market}/trades.json?limit=100&last_timestamp=#{(currentTime.to_time.to_i-(86400))*1000}")["trades"]["entries"]}
    for i in 1..15 do
      newTrades_per_market = markets.map{ |market| 
        response = HTTParty.get(url+"markets/#{market}/trades.json?timestamp=#{(currentTime.to_time.to_i-(5400*i))*1000}&limit=100&last_timestamp=#{(currentTime.to_time.to_i-(86400))*1000}")
        #Due to 429 error throwed by buda's API (Too many requests)
        if response.code!=200
          puts "sleeping"
          sleep(20)
          response = HTTParty.get(url+"markets/#{market}/trades.json?timestamp=#{(currentTime.to_time.to_i-(5400*i))*1000}&limit=100&last_timestamp=#{(currentTime.to_time.to_i-(86400))*1000}")
        end
        response["trades"]["entries"]
      }
      trades_per_market = trades_per_market.map.with_index{ |x,index| x + newTrades_per_market[index]}
    end

    valores_per_market = trades_per_market.map{ |trades| trades.map{ |trade| trade[1].to_f*trade[2].to_f}}

    max_value_per_market = valores_per_market.map{ |values| values.max}
    max_value_per_market.each_with_index{ |max_value,index| Transaction.new(value: max_value,market:markets[index]).save}

    @transactions = Transaction.all
  end
end
