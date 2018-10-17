# Player used by Client and Server
class Player
  attr_accessor :x, :y, :id, :name

  def initialize(id, x, y, name = 'def')
    @id = id
    @x = x
    @y = y
    @name = name

  end

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

  def move_left
    @x -= 20
  end

  def move_right
    @x += 20
  end

  # create name package str
  def to_n_pck
    name = @name.ljust(5, '_')
    format("%02d#{name}", @id)
  end

  def to_s
    "#{'%02d' % @id}#{'%03d' % @x}#{'%03d' % @y}"
  end
end
