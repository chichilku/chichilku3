class GameLogic
  def initialize(console)
    @console = console
  end

  def handle_client_requests(data, id, players, dt)
    player = Player.get_player_by_id(players, id)

    gravity(player, dt)
    player.tick

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
      @console.dbg "player=#{id} wants to jump"
      player.do_jump
    end

    # reset values (should stay last)
    player.reset_collide

    # return updated players
    players
  end

  def gravity(player, dt)
    if player.y > 420
      # player.collide[:down] = true
      player.do_collide(:down, true)
      return
    end


    # grav = 100000 * dt
    # @console.log "grav: #{grav}"
    # player.y += grav
    player.dy += 2 if player.dy < 16
  end
end
