class RektController < ApplicationController

  
  def index
    render :layout => 'application'
  end
  


  def show
    render :layout => 'calc'
    
    #get the current user's summoner info
    @summoner_name = params[:name]
    result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v1.4/summoner/by-name/'+@summoner_name+'?api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
    @summoner = JSON.parse result
    
    # #get current game info
    result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/observer-mode/rest/consumer/getSpectatorGameInfo/NA1/'+@summoner[@summoner_name]["id"].to_s+'?api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
    @current_game = JSON.parse result
    
    #get all players in current game by team
    @team_1 = Array.new
    @team_2 = Array.new 
    @my_team_id = 0
    @current_game["participants"].each do |player|
      temp = {"summonerId" => player["summonerId"], "summonerName" => player["summonerName"], "championId" => player["championId"],"totalGamePlayed" => 0, "totalGameWon" => 0, "GameWinRate" => 0.0, "totalGamePlayedAsChampion" => 0, "totalGameWonAsChampion" => 0, "GameWinRateAsChampion" => 0.0, "LeagueTier" => "PLASTIC", "LeagueDivision" => "O"}
      if player["summonerId"] == @summoner[@summoner_name]["id"]
        @my_team_id = player["teamId"]
      end
      if player["teamId"] == 100
        @team_1 << temp
      else
        @team_2 << temp
      end
    end
    
    #get totalGamePlayed, totalGameWon, GameWinRate, totalGamePlayedAsChampion, totalGameWonAsChampion, GameWinRateAsChampion LeagueTier, and LeagueDivision for opponent team
    if @my_team_id == 100
      @opponent_team = @team_2
    else
      @opponent_team = @team_1
    end
    @opponent_team.map! do |player|
      #get the summoner ranked game info for each champion 
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

    # #get all players in current game by team
    # @team_1 = Array.new
    # @team_2 = Array.new 
    # @current_game["participants"].each do |player|
    #   temp = {"summonerId" => player["summonerId"], "summonerName" => player["summonerName"], "championId" => player["championId"],"totalGamePlayed" => 0, "totalGameWon" => 0, "GameWinRate" => 0.0, "totalGamePlayedAsChampion" => 0, "totalGameWonAsChampion" => 0, "GameWinRateAsChampion" => 0.0}
    #   if player["teamId"] == 100
    #     @team_1 << temp
    #   else
    #     @team_2 << temp
    #   end
    # end
    
    # #get totalGamePlayed, totalGameWon, GameWinRate, totalGamePlayedAsChampion, totalGameWonAsChampion and GameWinRateAsChampion for both team
    # @team_1.map! do |player|
    #   result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/'+player["summonerId"].to_s+'?beginIndex=0&endIndex=15&api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
    #   match_history = JSON.parse result
    #   match_history["matches"].each do |match|
    #     player["totalGamePlayed"] += 1
    #     if match["participants"][0]["stats"]["winner"]
    #       player["totalGameWon"] += 1
    #     end
    #     if match["participants"][0]["championId"] == player["championId"]
    #       player["totalGamePlayedAsChampion"] += 1
    #       if match["participants"][0]["stats"]["winner"]
    #         player["totalGameWonAsChampion"] += 1
    #       end
    #     end
    #   end
    #   player["GameWinRate"] = player["totalGameWon"].to_f / player["totalGamePlayed"] * 100
    #   player
    # end
    
    # @team_2.map! do |player|
    #   result = Net::HTTP.get(URI.parse('https://na.api.pvp.net/api/lol/na/v2.2/matchhistory/'+player["summonerId"].to_s+'?beginIndex=0&endIndex=15&api_key=fc908f24-2c88-4ed9-80a6-d072ada9ed05'))
    #   match_history = JSON.parse result
    #   match_history["matches"].each do |match|
    #     player["totalGamePlayed"] += 1
    #     if match["participants"][0]["stats"]["winner"]
    #       player["totalGameWon"] += 1
    #     end
    #     if match["participants"][0]["championId"] == player["championId"]
    #       player["totalGamePlayedAsChampion"] += 1
    #       if match["participants"][0]["stats"]["winner"]
    #         player["totalGameWonAsChampion"] += 1
    #       end
    #     end
    #   end
    #   player["GameWinRate"] = player["totalGameWon"].to_f / player["totalGamePlayed"] * 100
    #   player
    # end
    
  end
end
