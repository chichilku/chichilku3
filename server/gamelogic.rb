class GameLogic
  def initialize(console)
    @console = console
  end

  def handle_client_requests(data, id, players, dt)
    player = Player.get_player_by_id(players, id)


    # move requets
    if data[0] == '1'
      @console.dbg "player=#{id} wants to walk left"
      player.move_left
    end
    if data[1] == '1'
      @console.dbg "player=#{id} wants to walk right"
      player.move_right
    end
    if data[2] == '1'
      @console.log "player=#{id} wants to jump"
    end

    # @console.log "dt: #{dt}"
    gravity(player, dt)
    players
  end

  def gravity(player, dt)
    return if player.y > 400

    # grav = 100000 * dt
    # @console.log "grav: #{grav}"
    # player.y += grav
    player.y += 1
  end
end
