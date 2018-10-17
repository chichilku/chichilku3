class GameLogic
  def initialize(console)
    @console = console
  end

  def handle_client_requests(data, id, players)
    # TODO get the player object
    # and pass it to multiple functions to do all the magic


    # move requets
    if data[0] == '1'
      @console.dbg "player=#{id} wants to walk left"
      Player.get_player_by_id(players, id).move_left
    end
    if data[1] == '1'
      @console.dbg "player=#{id} wants to walk right"
      Player.get_player_by_id(players, id).move_right
    end
    players
  end
end
