class GameLogic
  def initialize(console)
    @console = console
    @alive_players = 0
  end

  def check_collide(players, player)
    players.each do |other|
      next if other == player
      next if !player.collide[:down]

      x_force = player.check_player_collide(other)
      player.apply_force(x_force, -8) if !x_force.zero?
    end
  end

  def handle_client_requests(data, id, players, dt)
    player = Player.get_player_by_id(players, id)
    if player.nil?
      @console.log "WARNING failed to update nil player with id=#{id}"
      if players.count > 0
        @console.log "connected players:"
      else
        @console.log "no players currently connected!"
      end
      players.each do |p|
        @console.log "id=#{p.id} name='#{p.name}'"
      end
      return players
    end

    gravity(player, dt)
    player.tick
    # player collsions works
    # but it eats performance and delays jumping
    check_collide(players, player)

    # move request
    if data[0] == '1'
      @console.log "player=#{id} space for more"
    end
    if data[1] == '1'
      @console.dbg "player=#{id} wants to walk left"
      player.move_left
    end
    if data[2] == '1'
      @console.dbg "player=#{id} wants to walk right"
      player.move_right
    end
    if data[3] == '1'
      @console.dbg "player=#{id} wants to jump"
      player.do_jump
    end

    # reset values (should stay last)
    player.reset_collide

    # return updated players
    players
  end

  def gravity(player, dt)
    if player.dead
      player.dead_ticks += 1
      if player.dead_ticks > 3
        player.dead = false
        player.die
      end
    else
      if player.y > 320 # too far down --> die
        player.dead = true
        player.dead_ticks = 0
      end
    end

    # outside of the save zone
    if player.x < 214 || player.x > 818 || player.dead
      if player.y > 420
        # player.collide[:down] = true
        player.do_collide(:down, true)
        return
      end
    else # on the save zone
      if player.y > 260
        # player.collide[:down] = true
        player.do_collide(:down, true)
        return
      end
    end

    # grav = 100000 * dt
    # @console.log "grav: #{grav}"
    # player.y += grav
    player.dy += 2 if player.dy < 16
  end
end
