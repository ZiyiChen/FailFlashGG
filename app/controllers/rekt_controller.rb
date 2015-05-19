include ActionView::Helpers::NumberHelper
class RektController < ApplicationController

  
  def index
    render :layout => 'application'
  end
  
  def get_summoner_by_name (name)
    result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/'+name+'?api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
    @summoner = JSON.parse result
  end
  
  def get_current_game_by_summoner_id (id)
    result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/observer-mode/rest/consumer/getSpectatorGameInfo/NA1/'+id.to_s+'?api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
    current_game = JSON.parse result
    #get all players in current game by team
    @team_1 = Array.new
    @team_2 = Array.new 
    $my_team_id = 0
    current_game["participants"].each do |player|
      temp = {"summonerId" => player["summonerId"], "summonerName" => player["summonerName"], "championId" => player["championId"],"totalGamePlayed" => 1, "totalGameWon" => 0,  "totalGameLost" => 0, "GameWinRate" => 0.0, "totalGamePlayedAsChampion" => 1, "totalGameWonAsChampion" => 0, "totalGameLostAsChampion" => 0, "GameWinRateAsChampion" => 0.0, "LeagueTier" => "PLASTIC", "LeagueDivision" => "O", "chanceOfWinningGame" => 0.0}
      if player["summonerId"] == @summoner[@summoner_name]["id"]
        logger.debug "HIT"
        logger.debug "player sum name #{player["summonerName"]}"
        $summoner = temp
        $my_team_id = player["teamId"]
      end
      if player["teamId"] == 100
        @team_1 << temp
      else
        @team_2 << temp
      end
    end
  end
  
  def get_rank_info_by_player (player)
    result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v1.3/stats/by-summoner/'+player["summonerId"].to_s+'/ranked?season=SEASON2015&api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
      ranked_stats = JSON.parse result
      ranked_stats["champions"].each do |champion|
        if champion["id"] == player["championId"]
          player["totalGamePlayedAsChampion"] += champion["stats"]["totalSessionsPlayed"]
          player["totalGameWonAsChampion"] += champion["stats"]["totalSessionsWon"]
          player["totalGameLostAsChampion"] += player["totalGamePlayedAsChampion"] - player["totalGameWonAsChampion"]
          player["GameWinRateAsChampion"] += (player["totalGameWonAsChampion"].to_f / player["totalGamePlayedAsChampion"].to_f).round(2)
        end
      end
      player["GameWinRate"] = (player["totalGameWon"].to_f / player["totalGamePlayed"] * 100).round(2)
      
      #get the summoner league info
      result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v2.5/league/by-summoner/'+player["summonerId"].to_s+'/entry?api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
      league = JSON.parse result
      logger.debug league[player["summonerId"].to_s].to_s
      player["LeagueTier"] = league[player["summonerId"].to_s][0]["tier"]
      player["totalGameWon"] += league[player["summonerId"].to_s][0]["entries"][0]["wins"]
      player["totalGameLost"] += league[player["summonerId"].to_s][0]["entries"][0]["losses"]
      player["totalGamePlayed"] += player["totalGameWon"] + league[player["summonerId"].to_s][0]["entries"][0]["losses"]
      player["GameWinRate"] += player["totalGameWon"].to_f / player["totalGamePlayed"].to_f
      player["LeagueDivision"] = league[player["summonerId"].to_s][0]["entries"][0]["division"]
      player["chanceOfWinningGame"] += ((player["GameWinRateAsChampion"] + player["GameWinRate"]) / 2.0 * 100).round(2)
    player
  end

def search
    #get the current user's summoner info
    @summoner_name = params[:name].strip.downcase
    logger.debug "sum name #{@summoner_name}"
    @summoner = get_summoner_by_name (@summoner_name)
    logger.debug @summoner.to_s
    #get current game info
    get_current_game_by_summoner_id (@summoner[@summoner_name]["id"])
    logger.debug "sum #{$summoner["summonerName"]}"
    
    #get totalGamePlayed, totalGameWon, GameWinRate, totalGamePlayedAsChampion, totalGameWonAsChampion, GameWinRateAsChampion LeagueTier, and LeagueDivision for opponent team
    if $my_team_id == 100
      $opponent_team = @team_2
    else
      $opponent_team = @team_1
    end
    $summoner = get_rank_info_by_player ($summoner)
#     $opponent_team.map! do |player|
#       #get the summoner ranked game info for each champion 
#       get_rank_info_by_player(player)
#      end
  redirect_to(:action => 'show')
  end

def show
  render :layout => 'calc'
end

end
