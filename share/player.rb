# Player used by Client and Server
require_relative 'console'

SPAWN_X = 200
SPAWN_Y = 100

class Player
  attr_accessor :x, :y, :dy, :dx, :id, :name
  attr_reader :collide

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
    if @y < 0
      die
    elsif @y > 500 # TODO: unhardcode me
      die
    end
  end

  def die
    $console.log("[death] name=#{@name} id=#{@id}")
    @x = SPAWN_X
    @y = SPAWN_Y
  end

  def move_left
    # @dx = -8
    @x -= 8
  end

  def move_right
    # @dx = 8
    @x += 8
  end

  def do_jump
    @dy = -20
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
