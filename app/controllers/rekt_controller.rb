class RektController < ApplicationController
  
  
  def index
  end
  
  def search 
  end

  def show
    @summoner_name = params[:name]
    result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/'+@summoner_name+'?api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
    @summoner = JSON.parse result
  end
end
