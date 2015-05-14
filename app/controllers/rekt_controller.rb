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
      temp = {"summonerId" => player["summonerId"], "summonerName" => player["summonerName"], "championId" => player["championId"],"totalGamePlayed" => 0, "totalGameWon" => 0, "GameWinRate" => 0.0, "totalGamePlayedAsChampion" => 0, "totalGameWonAsChampion" => 0, "GameWinRateAsChampion" => 0.0, "LeagueTier" => "PLASTIC", "LeagueDivision" => "O"}
      if player["summonerId"] == @summoner[@summoner_name]["id"]
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
        end
      end
      player["GameWinRate"] = player["totalGameWon"].to_f / player["totalGamePlayed"] * 100
      
      #get the summoner league info
      result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v2.5/league/by-summoner/'+player["summonerId"].to_s+'?api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
      league = JSON.parse result
      player["LeagueTier"] = league[player["summonerId"]][0]["tier"]
      league[player["summonerId"]][0]["entries"].each do |entry|
        if entry["playerOrTeamId"] == player["summonerId"]
          player["totalGameWon"] += entry["wins"]
          player["totalGamePlayed"] += player["totalGameWon"] + entry["losses"]
          player["LeagueDivision"] = entry["division"]
        end
      end
    player
  end

  def show
    render :layout => 'calc'
    #get the current user's summoner info
    @summoner_name = params[:name]
    get_summoner_by_name (@summoner_name)
    
    #get current game info
    get_current_game_by_summoner_id (@summoner[@summoner_name]["id"])
    
    #get totalGamePlayed, totalGameWon, GameWinRate, totalGamePlayedAsChampion, totalGameWonAsChampion, GameWinRateAsChampion LeagueTier, and LeagueDivision for opponent team
    if $my_team_id == 100
      $opponent_team = @team_2
    else
      $opponent_team = @team_1
    end
    $opponent_team.map! do |player|
      #get the summoner ranked game info for each champion 
      get_rank_info_by_player(player)
#     end
  end

end
