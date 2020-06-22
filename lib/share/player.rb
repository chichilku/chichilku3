# Player used by Client and Server
require_relative 'console'
require_relative 'network'
require_relative 'projectile'

SPAWN_X = 512
SPAWN_Y = 100

class Player
  attr_accessor :x, :y, :dy, :dx, :id, :name, :score, :state, :dead, :dead_ticks, :was_crouching
  attr_accessor :aimX, :aimY, :projectile, :fire_ticks
  attr_reader :collide, :collide_str, :img_index, :version, :w, :h

  def initialize(id, score, x = nil, y = nil, name = 'def', ip = nil)
    @id = id
    @x = x.nil? ? SPAWN_X : x
    @y = y.nil? ? SPAWN_Y : y
    @w = TILE_SIZE / 2
    @h = TILE_SIZE
    @aimX = 0
    @aimY = 0
    @projectile = Projectile.new
    @dx = 0
    @dy = 0
    @collide = {up: false, down: false, right: false, left: false}
    @state = {bleeding: false, crouching: false, fire: 0}
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
    @version = nil
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
    if @x != @last_x
      new_x = true
    end
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

  def self.update_player(players, id, x, y, score, aimX, aimY)
    player = get_player_by_id(players, id)
    player.x = x
    player.y = y
    player.score = score
    player.aimX = aimX
    player.aimY = aimY
    player
  end

  ###############
  # server only #
  ###############

  def set_version(version)
    @version = version
  end

  def tick
    move_x(@dx)
    move_y(@dy)
    @dx = normalize_zero(@dx)
    @dy = normalize_zero(@dy)
    check_out_of_world
    if @bleed_ticks > 0
      @bleed_ticks -= 1
      self.state[:bleeding] = @bleed_ticks.zero? == false
    end
  end

  def check_player_collide(other)
    # $console.log "x: #{@x} y: #{@y} ox: #{other.x} oy: #{other.y}"
    # x crash is more rare so make it the outer condition
    if other.x + other.w > @x && other.x < @x + @w
      if other.y + other.h > @y && other.y < @y + @h
        # $console.log "collide!"
        return @x < other.x ? -7 : 7
      end
    end
    return 0
  end

  def damage
    @bleed_ticks = 3
  end

  # def check_out_of_world #die
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
  def check_out_of_world # swap size
    # y
    if @y < 0
      die
    elsif @y > WINDOW_SIZE_Y
      die
    end
    # x ( comment me out to add the glitch feature agian )
    if @x < 0
      @x = WINDOW_SIZE_X - @w - 2
    elsif @x > WINDOW_SIZE_X - @w - 1
      @x = 0
    end
  end

  def die
    $console.log("[death] id=#{@id} name='#{@name}'")
    @x = SPAWN_X
    @y = SPAWN_Y
  end

  #TODO: check for collision before update
  # if move_left or move_right set u on a collided field
  # dont update the position or slow down speed
  # idk make sure to not get stuck in walls
  def move_left
    # @dx = -8
    @x -= state[:crouching] ? 4 : 8
  end

  def move_right
    # @dx = 8
    @x += state[:crouching] ? 4 : 8
  end

  def apply_force(x, y)
    @dx += x
    @dy += y
  end

  def do_jump
    return if !@collide[:down]

    if @dead 
      @dy = -5
    else
      @dy = state[:crouching] ? -20 : -30
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
    if position == :right && @dx > 0
      @dx = 0
    elsif position == :left && @dx < 0
      @dx = 0
    elsif position == :down && @dy > 0
      @dy = 0
    elsif position == :up && @dy < 0
      @dy = 0
    end
    @collide[position] = value
  end

  def reset_collide
    @collide = {up: false, down: false, right: false, left: false}
  end

  ##
  # Creates name package str
  #
  # only used by server
  #
  # @return [String] partial network packet

  def to_n_pck
    name = @name.ljust(NAME_LEN, '_')
    # format("%02d#{name}", @id) # old 2 char ids
    "#{@id}#{net_pack_int(@score)}#{name}" # new 1 char id
  end

  def to_s
    # "#{'%02d' % @id}#{'%03d' % @x}#{'%03d' % @y}" # old 2 char ids
    # "#{@id}#{net_pack_int(@score)}#{'%03d' % @x}#{'%03d' % @y}" # old 3 char coords
    pos="#{net_pack_bigint(@x, 2)}#{net_pack_bigint(@y, 2)}"
    proj=@projectile.r.to_i.to_s # hack nil to "0"
    proj+="#{net_pack_bigint(@projectile.x, 2)}#{net_pack_bigint(@projectile.y, 2)}"
    aim="#{net_pack_bigint(@aimX, 2)}#{net_pack_bigint(@aimY, 2)}"
    "#{@id}#{net_pack_int(@score)}#{state_to_net()}#{proj}#{aim}#{pos}" # new 2 char coords
  end

  def state_to_net
    @w = TILE_SIZE / 2
    @h = TILE_SIZE
    if @state[:bleeding] && @state[:crouching]
      "s"
    elsif @state[:bleeding] && @state[:fire] == 1
      "x"
    elsif @state[:bleeding] && @state[:fire] == 2
      "y"
    elsif @state[:bleeding] && @state[:fire] == 3
      "z"
    elsif @state[:bleeding]
      "b"
    elsif @state[:crouching]
      @w = TILE_SIZE
      @h = TILE_SIZE / 2
      "c"
    elsif @state[:fire] == 1
      "1"
    elsif @state[:fire] == 2
      "2"
    elsif @state[:fire] == 3
      "3"
    else
      "0"
    end
  end

  def net_to_state(net)
    if net == "b"
      @state = {bleeding: true, crouching: false, fire: 0}
    elsif net == "c"
      @state = {bleeding: false, crouching: true, fire: 0}
    elsif net == "s"
      @state = {bleeding: true, crouching: true, fire: 0}
    elsif net == "x"
      @state = {bleeding: true, crouching: false, fire: 1}
    elsif net == "y"
      @state = {bleeding: true, crouching: false, fire: 2}
    elsif net == "z"
      @state = {bleeding: true, crouching: false, fire: 3}
    elsif net == "1"
      @state = {bleeding: false, crouching: false, fire: 1}
    elsif net == "2"
      @state = {bleeding: false, crouching: false, fire: 2}
    elsif net == "3"
      @state = {bleeding: false, crouching: false, fire: 3}
    else
      @state = {bleeding: false, crouching: false, fire: 0}
    end
  end

  private

  def move_x(x)
    return if x < 0 && @collide[:left]
    return if x > 0 && @collide[:right]

    @x += x
  end

  def move_y(y)
    return if y < 0 && @collide[:up]
    return if y > 0 && @collide[:down]

    @y += y
  end

  # This method puts the value towards zero
  # used to normalize speed
  def normalize_zero(x)
    return x if x.zero?

    return x - 1 if x > 0
    x + 1
  end
end
