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

  def tick(players, dt)
    players.each do |player|
      # reset values (should stay first)
      player.reset_collide

      gravity(player, dt)
      player.tick
      # player collsions works
      # but it eats performance and delays jumping
      check_collide(players, player)
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

    # reset values (should stay first)
    player.state[:crouching] = false

    # move request
    if data[0] == '1'
      @console.dbg "player=#{id} wants to crouch"
      player.state[:crouching] = true
      player.x -= TILE_SIZE / 4 unless player.was_crouching
      player.was_crouching = true
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
    player.aimX = net_unpack_bigint(data[4..5])
    player.aimY = net_unpack_bigint(data[6..7])

    player.check_out_of_world

    # return updated players
    players
  end

  def posttick(players, dt)
    players.each do |player|
      # stopped crouching -> stand up
      if player.was_crouching && player.state[:crouching] == false
        player.y -= TILE_SIZE
        player.x += TILE_SIZE / 4
        player.was_crouching = false
      end
    end
  end

  def gravity(player, dt)
    if player.dead
      player.dead_ticks += 1
      player.state[:bleeding] = true
      if player.dead_ticks > 3
        player.dead = false
        player.state[:bleeding] = false
        player.die
      end
    else
      if player.y + player.h > 384 # too far down --> die
        player.dead = true
        player.dead_ticks = 0
      end
    end

    # outside of the save zone
    if player.x < 214 || player.x > 800 || player.dead
      if player.y + player.h > 484
        # player.collide[:down] = true
        player.do_collide(:down, true)
        return
      end
    else # on the save zone
      if player.y + player.h > 324
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
