require 'gosu'
require_relative 'client'
require_relative '../share/console'
require_relative '../share/player'

# Main Game getting gui form gosu
class Gui < Gosu::Window
  def initialize(cfg)
    super WINDOW_SIZE_X, WINDOW_SIZE_Y
    self.caption = 'Gui Game'
    @background_image = Gosu::Image.new("client/img/background1024x512.png")
    @stick = Gosu::Image.new("client/img/stick32.png")
    @x = 0
    @y = 0
    @players = []
    @cfg = cfg
    @state = STATE_CONNECTING
    @console = Console.new
    @net_client = Client.new(@console, @cfg)
    @font = Gosu::Font.new(20)
  end

  # def update_pos(server_data)
  #   server_data = server_data.split('')
  #   @x = server_data[0].to_i * 20
  #   @y = server_data[1].to_i * 20
  # end

  def update
    net_request = '000'.split('')
    if button_down?(4)    # a
      net_request[0] = '1'
    elsif button_down?(7) # d
      net_request[1] = '1'
    end

    # Networking
    net_data = @net_client.tick(net_request)
    return if net_data.nil?

    @state = net_data[1][:state]
    return if net_data[1][:skip]

    @players = net_data[0]
  end

  def draw
    @background_image.draw(0, 0, 0)
    # draw_quad(0, 0, 0xffff8888, WINDOW_SIZE_X, WINDOW_SIZE_Y, 0xffffffff, 0, 0, 0xffffffff, WINDOW_SIZE_X, WINDOW_SIZE_Y, 0xffffffff, 0)
    if @state == STATE_CONNECTING
      @font.draw_text("connecting to #{@cfg.data['ip']}...", 20, 20, 0, 2, 5)
    elsif @state == STATE_INGAME
      @players.each do |player|
        @console.dbg "drawing player id=#{player.id} pos=#{player.x}/#{player.y}"
        # draw_rect(player.x, player.y, TILE_SIZE, TILE_SIZE, Gosu::Color::WHITE)
        @stick.draw(player.x, player.y, 0)
        @font.draw_text(player.name, player.x, player.y - TILE_SIZE, 0, 1, 1)
      end
    else
      @font.draw_text('UNKOWN CLIENT STATE!!!', 20, 20, 0, 2, 10)
    end
  end
end
