# frozen_string_literal: true

# high level game logic
class GameLogic
  def initialize(console)
    @console = console
    @alive_players = 0
  end

  def on_player_connect(client, players)
    player = Player.get_player_by_id(players, client[PLAYER_ID])
    return if player.nil?

    port, ip = Socket.unpack_sockaddr_in(client[NET_CLIENT].getpeername)
    @console.log "player joined ID=#{player.id} IP=#{ip}:#{port} name='#{player.name}'"
  end

  def on_player_disconnect(client, players)
    player = Player.get_player_by_id(players, client[PLAYER_ID])
    return if player.nil?

    @console.log "player left ID=#{player.id} name='#{player.name}'"
  end

  def check_collide(players, player)
    players.each do |other|
      next if other == player
      next unless player.collide[:down]

      x_force = player.check_player_collide(other)
      player.apply_force(x_force, -8) unless x_force.zero?
    end
  end

  def tick(map, players, dt, tick)
    players.each do |player|
      # reset values (should stay first)
      player.reset_collide

      map_collision(map, player)
      gravity(map, player, dt, tick)
      player.tick
      player.projectile.tick(players)
      # player collsions works
      # but it eats performance and delays jumping
      check_collide(players, player)
    end
  end

  def map_collision(map, player)
    # left bottom
    col = map.collision?(player.x / TILE_SIZE, (player.y + player.h) / TILE_SIZE)
    if col
      player.y = (col[:y] - 1) * TILE_SIZE
      player.y += TILE_SIZE / 2 if player.state[:crouching]
      player.do_collide(:down, true)
    end
    # right bottom
    col = map.collision?((player.x + player.w) / TILE_SIZE, (player.y + player.h) / TILE_SIZE)
    if col
      player.y = (col[:y] - 1) * TILE_SIZE
      player.y += TILE_SIZE / 2 if player.state[:crouching]
      player.do_collide(:down, true)
    end
    # left top
    col = map.collision?(player.x / TILE_SIZE, player.y / TILE_SIZE)
    if col
      player.y = (col[:y] * TILE_SIZE) + player.h
      player.do_collide(:up, true)
    end
    # right top
    col = map.collision?((player.x + player.w) / TILE_SIZE, player.y / TILE_SIZE)
    if col
      player.y = (col[:y] * TILE_SIZE) + player.h
      player.do_collide(:up, true)
    end
    nil
  end

  def handle_client_requests(data, id, players, _dt)
    player = Player.get_player_by_id(players, id)
    if player.nil?
      @console.log "WARNING failed to update nil player with id=#{id}"
      if players.count.positive?
        @console.log 'connected players:'
      else
        @console.log 'no players currently connected!'
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
    if data[1] == 'l'
      @console.dbg "player=#{id} wants to walk left"
      player.move_left
    end
    if data[1] == 'r'
      @console.dbg "player=#{id} wants to walk right"
      player.move_right
    end
    if data[2] == '1'
      @console.dbg "player=#{id} wants to jump"
      player.do_jump
    end
    if data[3] == '1' && player.state[:crouching] == false
      @console.dbg "player=#{id} wants to fire"
      player.fire_ticks += 1
      if player.fire_ticks > 29
        player.state[:fire] = 3
      elsif player.fire_ticks > 19
        player.state[:fire] = 2
      elsif player.fire_ticks > 9
        player.state[:fire] = 1
      end
    else
      if player.fire_ticks.positive?
        dx = (player.aim_x - player.x).clamp(-200, 200) / 20
        dy = (player.aim_y - player.y).clamp(-200, 200) / 20
        dx *= (player.fire_ticks / 10).clamp(1, 3)
        dy *= (player.fire_ticks / 10).clamp(1, 3)
        player.projectile.fire(player.x + TILE_SIZE / 4, player.y + TILE_SIZE / 2, dx, dy, player)
      end
      player.fire_ticks = 0
      player.state[:fire] = 0
    end
    player.aim_x = net_unpack_bigint(data[4..5])
    player.aim_y = net_unpack_bigint(data[6..7])
    # player.projectile.x = player.aim_x + 20
    # player.projectile.y = player.aim_y + 20

    player.check_out_of_world

    # return updated players
    players
  end

  def posttick(players, _dt)
    players.each do |player|
      # stopped crouching -> stand up
      next unless player.was_crouching && player.state[:crouching] == false

      player.y -= TILE_SIZE / 2
      player.x += TILE_SIZE / 4
      player.was_crouching = false
    end
  end

  def gravity(map, player, _dt, _tick)
    if player.dead
      player.dead_ticks += 1
      player.state[:bleeding] = true
      if player.dead_ticks > 3
        player.dead = false
        player.state[:bleeding] = false
        player.die
      end
    elsif map.death?(player.x / TILE_SIZE, (player.y + player.h) / TILE_SIZE)
      player.dead = true
      player.dead_ticks = 0
    end

    # grav = 100000 * dt
    # @console.log "grav: #{grav}"
    # player.y += grav
    player.dy += 1 if player.dy < 16
  end
end
