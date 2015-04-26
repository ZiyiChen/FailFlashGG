class RektController < ApplicationController
  def index
    result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v1.2/champion?api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
    @hash = JSON.parse result
  end
end
