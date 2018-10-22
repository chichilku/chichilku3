require 'gosu'
require_relative 'client'
require_relative '../share/console'
require_relative '../share/player'

$time_point=Time.now
$time_buffer=0

def get_frame_time
  diff = Time.now - $time_point
  $time_point = Time.now
  return diff
end

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
    @tick = 0
    @state = STATE_CONNECTING
    @console = Console.new
    @net_client = Client.new(@console, @cfg)
    @font = Gosu::Font.new(20)
    @is_debug = false
    
    @last_key_press = Time.now
  end

  # def update_pos(server_data)
  #   server_data = server_data.split('')
  #   @x = server_data[0].to_i * 20
  #   @y = server_data[1].to_i * 20
  # end

  def main_tick
    net_request = '000'.split('')
    if button_down?(4)    # a
      net_request[0] = '1'
    end
    if button_down?(7) # d
      net_request[1] = '1'
    end
    if button_down?(Gosu::KB_SPACE)
      net_request[2] = '1'
    end
    if button_down?(16) # m
      if @last_key_press < Time.now - 0.09
        @is_debug = !@is_debug
        @last_key_press = Time.now
      end
    end

    # Networking
    net_data = @net_client.tick(net_request, @tick)
    return if net_data.nil?

    @flags = net_data[1] # TODO: make this code nicer
    @state = net_data[1][:state]
    return if net_data[1][:skip]

    @players = net_data[0]
  end

  def update
    $time_buffer += get_frame_time
    if ($time_buffer > MAX_TICK_SPEED)
      @tick += 1
      main_tick
      $time_buffer = 0
    end
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

      if @is_debug
        player = Player.get_player_by_id(@players, @flags[:id])
        @font.draw_text("Press m to deactivate debug mode", 10, 10, 0, 1, 1)
        @font.draw_text("x: #{player.x} y: #{player.y}", 10, 30, 0, 1, 1)
        # thats useless because collide/delta speed is not sent over the network
        # @font.draw_text("dx: #{player.dx} dy: #{player.dy}", 10, 50, 0, 1, 1)
        # @font.draw_text(player.collide_string, 10, 70, 0, 1, 1)
      end
    else
      @font.draw_text('UNKOWN CLIENT STATE!!!', 20, 20, 0, 2, 10)
    end
  end
end
