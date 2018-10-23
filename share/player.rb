# Player used by Client and Server
require_relative 'console'

SPAWN_X = 200
SPAWN_Y = 100

class Player
  attr_accessor :x, :y, :dy, :dx, :id, :name
  attr_reader :collide, :collide_str, :img_index

  def initialize(id, x = nil, y = nil, name = 'def')
    @id = id
    # @x = x
    # @y = y
    @x = x.nil? ? SPAWN_X : x
    @y = y.nil? ? SPAWN_Y : y
    @dx = 0
    @dy = 0
    @collide = {up: false, down: false, right: false, left: false}
    @name = name

    # used by client
    @img_index = 0
    @last_x = 0
    @last_y = 0
    @tick = 0
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
    if @x != @last_x || @y != @last_y
      @img_index += 1
      @img_index = 0 if @img_index > 4
      # $console.log "img updated to: #{@img_index}"
    end
    @last_x = @x
    @last_y = @y
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

  def self.update_player(players, id, x, y)
    player = get_player_by_id(players, id)
    player.x = x
    player.y = y
    player
  end

  ###############
  # server only #
  ###############
  def tick
    move_x(@dx)
    move_y(@dy)
    @dx = normalize_zero(@dx)
    @dy = normalize_zero(@dy)
    check_out_of_world
  end

  def check_out_of_world
    # y
    if @y < 0
      die
    elsif @y > 500 # TODO: unhardcode me
      die
    end
    # x ( comment me out to add the glitch feature agian )
    if @x < 0
      die
    elsif @x > WINDOW_SIZE_X - TILE_SIZE - 1
      die
    end
  end

  def die
    $console.log("[death] name=#{@name} id=#{@id}")
    @x = SPAWN_X
    @y = SPAWN_Y
  end

  #TODO: check for collision before update
  # if move_left or move_right set u on a collided field
  # dont update the position or slow down speed
  # idk make sure to not get stuck in walls
  def move_left
    # @dx = -8
    @x -= 8
  end

  def move_right
    # @dx = 8
    @x += 8
  end

  def do_jump
    return if !@collide[:down]

    @dy = -30
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

  # create name package str
  def to_n_pck
    name = @name.ljust(5, '_')
    format("%02d#{name}", @id)
  end

  def to_s
    "#{'%02d' % @id}#{'%03d' % @x}#{'%03d' % @y}"
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

  private

  # This method puts the value towards zero
  # used to normalize speed
  def normalize_zero(x)
    return x if x.zero?

    return x - 1 if x > 0
    x + 1
  end
end
