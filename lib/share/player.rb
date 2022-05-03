# frozen_string_literal: true

# Player used by Client and Server
require_relative 'console'
require_relative 'network'
require_relative 'projectile'

SPAWN_X = 512
SPAWN_Y = 100

# Player objects represent stick figures
class Player
  attr_accessor :x, :y, :dy, :dx, :id, :name, :score, :state, :dead, :dead_ticks, :was_crouching, :aim_x, :aim_y,
                :projectile, :fire_ticks, :map_download
  attr_reader :collide, :collide_str, :img_index, :version, :w, :h

  def initialize(id, score, x = nil, y = nil, name = 'def', version = nil, ip = nil)
    @id = id
    @x = x.nil? ? SPAWN_X : x
    @y = y.nil? ? SPAWN_Y : y
    @w = PLAYER_SIZE / 2
    @h = PLAYER_SIZE
    @aim_x = 0
    @aim_y = 0
    @projectile = Projectile.new
    @dx = 0
    @dy = 0
    @health = 3
    @collide = { up: false, down: false, right: false, left: false }
    @state = { bleeding: false, crouching: false, fire: 0 }
    @was_crouching = false
    @name = name
    @score = score
    @dead = false # only used by server for now
    @dead_ticks = 0
    @bleed_ticks = 0
    @fire_ticks = 0

    # used by client
    @img_index = 0
    @last_x = 0
    @last_y = 0
    @tick = 0
    @not_changed_y = 0

    # used by server
    @map_download = -2
    @version = version
    @ip = ip
  end

  ###############
  # client only #
  ###############

  def draw_tick
    @tick += 1
    update_img
  end

  def update_img
    return if @tick % 5 != 0

    new_x = true if @x != @last_x
    if @y != @last_y
      new_y = true
      @not_changed_y = 0
    else
      @not_changed_y += 1
    end

    if new_x || new_y
      @img_index += 1
      @img_index = 0 if @img_index > 4
      # $console.log "img updated to: #{@img_index}"
    end
    @last_x = @x
    @last_y = @y
    # if @not_changed_y > 10
    #   $console.log "player is chillin"
    #   @img_index = 5
    # end
  end

  #####################
  # client and server #
  #####################
  def self.get_player_index_by_id(players, id)
    players.index(get_player_by_id(players, id))
  end

  def self.get_player_by_id(players, id)
    players.find { |player| id == player.id }
  end

  def self.update_player(players, id, x, y, score, aim_x, aim_y)
    player = get_player_by_id(players, id)
    player.x = x
    player.y = y
    player.score = score
    player.aim_x = aim_x
    player.aim_y = aim_y
    player
  end

  ###############
  # server only #
  ###############

  def tick
    move_x(@dx)
    move_y(@dy)
    @dx = normalize_zero(@dx)
    # @dy = normalize_zero(@dy)
    check_out_of_game_map
    return unless @bleed_ticks.positive?

    @bleed_ticks -= 1
    state[:bleeding] = @bleed_ticks.zero? == false
  end

  def check_player_collide(other)
    # $console.log "x: #{@x} y: #{@y} ox: #{other.x} oy: #{other.y}"
    # x crash is more rare so make it the outer condition
    if other.x + other.w > @x && other.x < @x + @w && (other.y + other.h > @y && other.y < @y + @h)
      # $console.log "collide!"
      return @x < other.x ? -7 : 7
    end

    0
  end

  def damage(attacker)
    @bleed_ticks = 3
    @health -= 1
    $console.log "'#{attacker.id}:#{attacker.name}' damaged '#{@id}:#{@name}'"
    die(attacker) if @health <= 0
  end

  # def check_out_of_game_map #die
  #   # y
  #   if @y < 0
  #     die
  #   elsif @y > WINDOW_SIZE_Y
  #     die
  #   end
  #   # x ( comment me out to add the glitch feature agian )
  #   if @x < 0
  #     die
  #   elsif @x > WINDOW_SIZE_X - TILE_SIZE - 1
  #     die
  #   end
  # end
  # swap size
  def check_out_of_game_map
    # y
    if @y.negative?
      die
    elsif @y >= WINDOW_SIZE_Y - TILE_SIZE
      die
    end
    # x ( comment me out to add the glitch feature agian )
    if @x.negative?
      @x = WINDOW_SIZE_X - @w - 2
    elsif @x > WINDOW_SIZE_X - @w - 1
      @x = 0
    end
  end

  def die(killer = nil)
    if killer.nil?
      $console.log("player ID=#{@id} name='#{@name}' died")
    else
      if killer.id == id
        killer.score -= 1
      else
        killer.score += 1
      end
      killer.score = killer.score.clamp(0, NET_MAX_INT)
      $console.log("player '#{@id}:#{@name}' was killed by '#{killer.id}:#{killer.name}'")
    end
    @x = SPAWN_X
    @y = SPAWN_Y
    @health = 3
  end

  # TODO: check for collision before update
  # if move_left or move_right set u on a collided field
  # dont update the position or slow down speed
  # idk make sure to not get stuck in walls

  def check_move_left(game_map)
    # left bottom
    col = game_map.collision?(@x / TILE_SIZE, (@y + @h - 1) / TILE_SIZE)
    if col
      @x = (col[:x] + 1) * TILE_SIZE
      @x += 1
      do_collide(:left, true)
    end

    # left top
    col = game_map.collision?(@x / TILE_SIZE, (@y + 1) / TILE_SIZE)
    if col
      @x = (col[:x] + 1) * TILE_SIZE
      @x += 1
      do_collide(:left, true)
    end
    nil
  end

  def check_move_right(game_map)
    # right bottom
    col = game_map.collision?((@x + @w) / TILE_SIZE, (@y + @h - 1) / TILE_SIZE)
    if col
      @x = col[:x] * TILE_SIZE
      @x -= state[:crouching] ? PLAYER_SIZE : PLAYER_SIZE / 2
      @x -= 1
      do_collide(:right, true)
    end

    # right top
    col = game_map.collision?((@x + @w) / TILE_SIZE, (@y + 1) / TILE_SIZE)
    if col
      @x = col[:x] * TILE_SIZE
      @x -= state[:crouching] ? PLAYER_SIZE : PLAYER_SIZE / 2
      @x -= 1
      do_collide(:right, true)
    end
    nil
  end

  def move_left(game_map)
    # @dx = -8
    @x -= state[:crouching] ? 4 : 8
    check_move_left(game_map)
  end

  def move_right(game_map)
    # @dx = 8
    @x += state[:crouching] ? 4 : 8
    check_move_right(game_map)
  end

  def apply_force(x, y)
    @dx += x
    @dy += y
  end

  def do_jump
    return unless @collide[:down]

    @dy = if @dead
            -5
          else
            state[:crouching] ? -15 : -20
          end
  end

  def add_score(score = 1)
    @score = (@score + score).clamp(NET_MIN_INT, NET_MAX_INT)
  end

  def collide_string
    str = "collide:\n"
    str += "down: #{@collide[:down]} up: #{@collide[:up]}\n"
    str += "left: #{@collide[:left]} right: #{@collide[:right]}"
    str
  end

  def do_collide(position, value)
    if position == :right && @dx.positive?
      @dx = 0
    elsif position == :left && @dx.negative?
      @dx = 0
    elsif position == :down && @dy.positive?
      @dy = 0
    elsif position == :up && @dy.negative?
      @dy = 0
    end
    @collide[position] = value
  end

  def reset_collide
    @collide = { up: false, down: false, right: false, left: false }
  end

  ##
  # Creates name package str
  #
  # only used by server
  #
  # @return [String] partial network packet

  def to_n_pck
    name = @name.ljust(NAME_LEN, ' ')
    "#{@id.to_s(16)}#{net_pack_int(@score)}#{name}"
  end

  def to_s
    pos = "#{net_pack_bigint(@x, 2)}#{net_pack_bigint(@y, 2)}"
    proj = @projectile.r.to_i.to_s # HACK: nil to "0"
    fake_y = @projectile.y.positive? ? @projectile.y : 0
    proj += "#{net_pack_bigint(@projectile.x, 2)}#{net_pack_bigint(fake_y, 2)}"
    aim = "#{net_pack_bigint(@aim_x, 2)}#{net_pack_bigint(@aim_y, 2)}"
    "#{@id.to_s(16)}#{net_pack_int(@score)}#{state_to_net}#{proj}#{aim}#{pos}"
  end

  def state_to_net
    @w = PLAYER_SIZE / 2
    @h = PLAYER_SIZE
    if @state[:bleeding] && @state[:crouching]
      's'
    elsif @state[:bleeding] && @state[:fire] == 1
      'x'
    elsif @state[:bleeding] && @state[:fire] == 2
      'y'
    elsif @state[:bleeding] && @state[:fire] == 3
      'z'
    elsif @state[:bleeding]
      'b'
    elsif @state[:crouching]
      @w = PLAYER_SIZE
      @h = PLAYER_SIZE / 2
      'c'
    elsif @state[:fire] == 1
      '1'
    elsif @state[:fire] == 2
      '2'
    elsif @state[:fire] == 3
      '3'
    else
      '0'
    end
  end

  def net_to_state(net)
    @state = case net
             when 'b'
               { bleeding: true, crouching: false, fire: 0 }
             when 'c'
               { bleeding: false, crouching: true, fire: 0 }
             when 's'
               { bleeding: true, crouching: true, fire: 0 }
             when 'x'
               { bleeding: true, crouching: false, fire: 1 }
             when 'y'
               { bleeding: true, crouching: false, fire: 2 }
             when 'z'
               { bleeding: true, crouching: false, fire: 3 }
             when '1'
               { bleeding: false, crouching: false, fire: 1 }
             when '2'
               { bleeding: false, crouching: false, fire: 2 }
             when '3'
               { bleeding: false, crouching: false, fire: 3 }
             else
               { bleeding: false, crouching: false, fire: 0 }
             end
  end

  private

  def move_x(x)
    return if x.negative? && @collide[:left]
    return if x.positive? && @collide[:right]

    @x += x
  end

  def move_y(y)
    return if y.negative? && @collide[:up]
    return if y.positive? && @collide[:down]

    @y += y
  end

  # This method puts the value towards zero
  # used to normalize speed
  def normalize_zero(x)
    return x if x.zero?

    return x - 1 if x.positive?

    x + 1
  end
end
