require 'gosu'
require_relative 'client'
require_relative '../share/console'
require_relative '../share/player'
require_relative 'gui'
require_relative 'client_cfg'

TILE_SIZE = 32
WINDOW_SIZE_X = TILE_SIZE * 32
WINDOW_SIZE_Y = TILE_SIZE * 16
SPEED = TILE_SIZE

# The project root is the game
class Game
  def initialize
    console = Console.new
    cfg = ClientCfg.new(console)
    gui = Gui.new(cfg)
    gui.show
  end
end

Game.new
