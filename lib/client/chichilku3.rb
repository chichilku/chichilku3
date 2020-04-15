require 'gosu'
require_relative 'client'
require_relative '../share/console'
require_relative '../share/player'
require_relative 'gui'
require_relative 'client_cfg'

# The project root is the game
class Game
  def initialize
    console = Console.new
    cfg = ClientCfg.new(console, "client.json")
    gui = Gui.new(cfg)
    gui.show
  end
end

Game.new
