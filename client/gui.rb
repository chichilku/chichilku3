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
    self.caption = 'chichilku3 client'
    # images
    @background_image = Gosu::Image.new("client/img/grass1024x512.png")
    @connecting_image = Gosu::Image.new("client/img/connecting1024x512.png")
    @stick = Gosu::Image.new("client/img/stick32.png")
    @stick_images = []
    @stick_images << Gosu::Image.new("client/img/stick32/stick0.png")
    @stick_images << Gosu::Image.new("client/img/stick32/stick1.png")
    @stick_images << Gosu::Image.new("client/img/stick32/stick2.png")
    # data
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
    @is_chat = false
    @chat_msg = ""
    @last_key = nil
    # @chat_inp_stream = nil #TextInput.new
    # @chat_inp_stream.text # didnt get it working
    
    @last_key_press = Time.now

    # depreciated ._.
    # @con_msg = Gosu::Image.from_text(self, "connecting to #{@cfg.data['ip']}:#{@cfg.data['port']}...", Gosu.default_font_name, 45)
  end

  # def update_pos(server_data)
  #   server_data = server_data.split('')
  #   @x = server_data[0].to_i * 20
  #   @y = server_data[1].to_i * 20
  # end

  def chat_tick
    if button_down?(Gosu::KB_ESCAPE)
      @is_chat = false
    elsif button_down?(Gosu::KB_RETURN)
      @is_chat = false
      return @chat_msg
    else
      if !button_down?(@last_key)
        @last_key = nil # refresh blocker
      end
      if button_down?(Gosu::KB_BACKSPACE)
        # press shift to fast delete
        if button_down?(Gosu::KB_LEFT_SHIFT) || @last_key != Gosu::KB_BACKSPACE
          @chat_msg = @chat_msg[0..-2]
          @last_key = Gosu::KB_BACKSPACE
        end
      end
      for key in 4..30 do # alphabet lowercase
        if button_down?(key)
          if @last_key != key
            @chat_msg += button_id_to_char(key)
            @last_key = key
          end
        end
      end
    end
    nil
  end

  def main_tick
    net_request = '000'.split('')
    protocol = 2

    if @is_chat
      msg = chat_tick
      if !msg.nil?
        # @console.dbg "rawmsg: #{msg}"
        msg = msg.ljust(3, '0')
        net_request = msg[0..2].split('')
        # @console.dbg "prepedmsg: #{net_request}"
        protocol = 4
      end
    else
      if button_down?(4) # a
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
      if button_down?(23) # t
        @last_key = 23
        @is_chat = true
        @chat_msg = ""
      end
    end

    # Networking
    net_data = @net_client.tick(net_request, protocol, @tick)
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
    # draw_quad(0, 0, 0xffff8888, WINDOW_SIZE_X, WINDOW_SIZE_Y, 0xffffffff, 0, 0, 0xffffffff, WINDOW_SIZE_X, WINDOW_SIZE_Y, 0xffffffff, 0)
    if @state == STATE_CONNECTING
      @connecting_image.draw(0, 0, 0)
      @font.draw_text("connecting to #{@cfg.data['ip']}:#{@cfg.data['port']}...", 20, 20, 0, 2, 5)
      # @con_msg.draw(100,200,0)
    elsif @state == STATE_INGAME
      @background_image.draw(0, 0, 0)
      @players.each do |player|
        player.draw_tick
        @console.dbg "drawing player id=#{player.id} pos=#{player.x}/#{player.y}"
        # draw_rect(player.x, player.y, TILE_SIZE, TILE_SIZE, Gosu::Color::WHITE)
        # @stick.draw(player.x, player.y, 0)
        @stick_images[player.img_index].draw(player.x, player.y, 0)
        if @is_debug # print id
          # @font.draw_text(player.id, player.x, player.y - TILE_SIZE * 2, 0, 1, 1)          
          @font.draw_text("#{player.id}:#{player.img_index}", player.x, player.y - TILE_SIZE * 2, 0, 1, 1)          
        end
        @font.draw_text(player.name, player.x, player.y - TILE_SIZE, 0, 1, 1)
      end

      if @is_chat
        @font.draw_text("> #{@chat_msg}", 10, 450, 0, 1, 1)
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
      @connecting_image.draw(0, 0, 0)
      @font.draw_text('UNKOWN CLIENT STATE!!!', 20, 20, 0, 2, 10)
    end
  end
end
