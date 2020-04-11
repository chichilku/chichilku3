require 'gosu'
require_relative 'client'
require_relative 'text'
require_relative 'scoreboard'
require_relative '../share/console'
require_relative '../share/player'

KEY_A = 4
KEY_C = 6
KEY_D = 7
KEY_H = 11
KEY_J = 13
KEY_K = 14
KEY_L = 15
KEY_M = 16
KEY_Q = 20
KEY_S = 22
KEY_T = 23
KEY_W = 26
KEY_RIGHT = 79
KEY_LEFT = 80
KEY_DOWN = 81
KEY_UP = 82

MENU_MAIN = 0
MENU_CONNECT = 1
MENU_SETTINGS = 2

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
    @background_image = Gosu::Image.new("client/img/battle1024x512.png")
    @connecting_image = Gosu::Image.new("client/img/connecting1024x512.png")
    @stick = Gosu::Image.new("client/img/stick32.png")
    @stick_images = []
    @stick_images << Gosu::Image.new("client/img/stick64/stick0.png")
    @stick_images << Gosu::Image.new("client/img/stick64/stick1.png")
    @stick_images << Gosu::Image.new("client/img/stick64/stick2.png")
    @stick_images << Gosu::Image.new("client/img/stick64/stick3.png")
    @stick_images << Gosu::Image.new("client/img/stick64/stick4.png")
    @stick_images << Gosu::Image.new("client/img/stick64/stick5.png")

    # @stick_images << Gosu::Image.new("client/img/stick32/stick0.png")
    # @stick_images << Gosu::Image.new("client/img/stick32/stick1.png")
    # @stick_images << Gosu::Image.new("client/img/stick32/stick2.png")
    # data
    @x = 0
    @y = 0
    @players = []
    @cfg = cfg
    @tick = 0
    @console = Console.new
    @net_client = Client.new(@console, @cfg)
    @net_err = nil
    @state = @net_client.state
    @menu_page = MENU_MAIN
    @font = Gosu::Font.new(20)
    @is_debug = false
    @is_chat = false
    @is_scoreboard = false
    @chat_msg = "" # what we type
    @server_chat_msg = "" # what we get from server
    @chat_show_time = 4
    @server_chat_recv = Time.now - @chat_show_time
    @last_key = nil
    @menu_items = []
    @selected_menu_item = 0
    @menu_textfield = TextField.new(self, 60, 200)
    # @chat_inp_stream = nil #TextInput.new
    # @chat_inp_stream.text # didnt get it working <--- nobo xd
    
    @last_key_press = Time.now
    @last_pressed_button = {}

    # depreciated ._.
    # @con_msg = Gosu::Image.from_text(self, "connecting to #{@cfg.data['ip']}:#{@cfg.data['port']}...", Gosu.default_font_name, 45)
    init_menu()
  end

  def button_press?(button)
    last_btn = @last_pressed_button[button]
    @last_pressed_button[button] = button_down?(button)
    return false if last_btn == true
    button_down?(button)
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
    if @state == STATE_MENU
      if @menu_page == MENU_CONNECT
        enter_ip_tick
      elsif @menu_page == MENU_SETTINGS
        enter_name_tick
      else
        menu_tick
      end
    elsif @state == STATE_ERROR
      if button_down?(Gosu::KB_ESCAPE)
        @state = STATE_MENU
      end
    else
      game_tick
    end
  end

  def enter_name_tick
    if button_down?(Gosu::KB_ESCAPE)
      @state = STATE_MENU
      @menu_page = MENU_MAIN
    elsif button_down?(Gosu::KB_RETURN)
      if @last_key != Gosu::KB_RETURN
        @cfg.data['username'] = @menu_textfield.text[0...NAME_LEN]
        @state = STATE_MENU
        @menu_page = MENU_MAIN
      end
    else
      @last_key = nil
    end
  end

  def enter_ip_tick
    if button_down?(Gosu::KB_ESCAPE)
      ip = @menu_textfield.text.split(":")
      @cfg.data['ip'] = ip[0]
      @cfg.data['port'] = ip[1] if ip.length > 1
      @state = STATE_MENU
      @menu_page = MENU_MAIN
    elsif button_press?(Gosu::KB_RETURN)
      if @last_key != Gosu::KB_RETURN
        ip = @menu_textfield.text.split(":")
        @cfg.data['ip'] = ip[0]
        @cfg.data['port'] = ip[1] if ip.length > 1
        connect
      end
    else
      @last_key = nil
    end
  end

  def menu_tick
    if button_down?(KEY_Q)
      puts "quitting the game."
      @cfg.save
      exit
    elsif button_down?(KEY_C)
      connect_menu
      return
    end
    if button_press?(KEY_DOWN) or button_press?(KEY_S) or button_press?(KEY_J) or button_press?(Gosu::MS_WHEEL_DOWN)
      @selected_menu_item += 1 if @selected_menu_item < @menu_items.length - 1
    elsif button_press?(KEY_UP) or button_press?(KEY_W) or button_press?(KEY_K) or button_press?(Gosu::MS_WHEEL_UP)
      @selected_menu_item -= 1 if @selected_menu_item > 0
    elsif button_press?(Gosu::KB_RETURN)
      @menu_items[@selected_menu_item][1].call
    end
  end

  def game_tick
    if button_down?(Gosu::KB_ESCAPE)
      if @state == STATE_CONNECTING
        @state = STATE_MENU
      elsif @state == STATE_INGAME
        # TODO: do some disconnect stuff here
        @state = STATE_MENU
        return
      end
    end
    net_request = '0000'.split('')
    protocol = 2

    if @is_chat
      msg = chat_tick
      if !msg.nil?
        # @console.dbg "rawmsg: #{msg}"
        msg = msg.ljust(4, '0')
        net_request = msg[0..3].split('')
        # @console.dbg "prepedmsg: #{net_request}"
        protocol = 4
      end
    else
      net_request[0] = '0' # space for more
      if button_down?(KEY_A)
        net_request[1] = '1'
      end
      if button_down?(KEY_D)
        net_request[2] = '1'
      end
      if button_down?(Gosu::KB_SPACE)
        net_request[3] = '1'
      end
      if button_down?(KEY_M)
        if @last_key_press < Time.now - 0.09
          @is_debug = !@is_debug
          @last_key_press = Time.now
        end
      end
      if button_down?(KEY_T)
        @last_key = KEY_T
        @is_chat = true
        @chat_msg = ""
      end
      @is_scoreboard = button_down?(Gosu::KB_TAB)
    end

    # Networking
    net_data = @net_client.tick(net_request, protocol, @tick)
    return if net_data.nil?

    @flags = net_data[1]
    @state = @flags[:state]
    msg = net_data[2]
    if msg
      type = msg[0]
      if type == 0
        @net_err = msg[1..-1]
        @state = STATE_ERROR
      elsif type == 1
        @server_chat_msg = msg[1]
        @server_chat_recv = Time.now
      end
    end
    return if @flags[:skip]

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

  def draw_main_menu
    @connecting_image.draw(0, 0, 0)
    offset = 0
    size = 2
    @menu_items.each_with_index do |menu_item, index|
      offset += 20 * size
      if index == @selected_menu_item
        @font.draw_text("> #{menu_item[0]} <", 20, 20 + offset, 0, size, size, Gosu::Color::GREEN)
      else
        @font.draw_text("   #{menu_item[0]}   ", 20, 20 + offset, 0, size, size)
      end
    end
  end

  def draw
    # draw_quad(0, 0, 0xffff8888, WINDOW_SIZE_X, WINDOW_SIZE_Y, 0xffffffff, 0, 0, 0xffffffff, WINDOW_SIZE_X, WINDOW_SIZE_Y, 0xffffffff, 0)
    if @state == STATE_MENU
      if @menu_page == MENU_CONNECT
        @connecting_image.draw(0, 0, 0)
        @font.draw_text("Enter server ip", 20, 20, 0, 5, 5)
        @menu_textfield.draw(0)
      elsif @menu_page == MENU_SETTINGS
        @connecting_image.draw(0, 0, 0)
        @font.draw_text("Choose a username", 20, 20, 0, 5, 5)
        @menu_textfield.draw(0)
      else
        draw_main_menu()
      end
    elsif @state == STATE_CONNECTING
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
          @font.draw_text("#{player.id}:#{player.score}", player.x, player.y - TILE_SIZE * 2, 0, 1, 1)          
          # @font.draw_text("#{player.id}:#{player.img_index}", player.x, player.y - TILE_SIZE * 2, 0, 1, 1)          
        end
        @font.draw_text(player.name, player.x, player.y - TILE_SIZE / 2, 0, 1, 1, 0xff_000000)
      end

      # chat input
      if @is_chat
        @font.draw_text("> #{@chat_msg}", 10, WINDOW_SIZE_Y - 30, 0, 1, 1)
      end

      # chat output
      if @server_chat_recv + @chat_show_time > Time.now
        @font.draw_text(@server_chat_msg, 10, WINDOW_SIZE_Y - 60, 0, 1, 1)
      end

      if @is_debug
        player = Player.get_player_by_id(@players, @flags[:id])
        @font.draw_text("Press m to deactivate debug mode", 10, 10, 0, 1, 1)
        @font.draw_text("x: #{player.x} y: #{player.y}", 10, 30, 0, 1, 1)
        @font.draw_text("gamestate: #{@flags[:gamestate]}", 10, 60, 0 , 1, 1)
        # thats useless because collide/delta speed is not sent over the network
        # @font.draw_text("dx: #{player.dx} dy: #{player.dy}", 10, 50, 0, 1, 1)
        # @font.draw_text(player.collide_string, 10, 70, 0, 1, 1)
      end

      if @is_scoreboard
        draw_scoreboard(WINDOW_SIZE_X, WINDOW_SIZE_Y, @players, @font)
      end
    elsif @state == STATE_ERROR
      net_err_code = @net_err[0]
      net_err_msg = @net_err[1]
      @connecting_image.draw(0, 0, 0)
      if net_err_code == NET_ERR_SERVER_OUTDATED || net_err_code == NET_ERR_CLIENT_OUTDATED
        server_version = net_err_msg[0..4]
        net_err_msg = net_err_msg[5..-1]
        @font.draw_text("Server version: #{server_version} Your version: #{GAME_VERSION}", 50, 150, 0, 2, 2)
      end
      @font.draw_text("#{NET_ERR[net_err_code]}", 50, 30, 0, 5, 5)
      @font.draw_text("#{net_err_msg}", 50, 200, 0, 2, 2)
    else
      @connecting_image.draw(0, 0, 0)
      @font.draw_text('UNKOWN CLIENT STATE!!!', 20, 20, 0, 2, 10)
    end
  end

  private

  def connect()
    @net_client.connect(@cfg.data['ip'], @cfg.data['port'])
    @state = STATE_CONNECTING;
    @menu_page = MENU_MAIN
  end

  def connect_menu()
    @last_key = Gosu::KB_RETURN
    self.text_input = @menu_textfield
    @menu_textfield.text = "#{@cfg.data['ip']}:#{@cfg.data['port']}"
    @state = STATE_MENU
    @menu_page = MENU_CONNECT
  end

  def settings_menu()
    @last_key = Gosu::KB_RETURN
    self.text_input = @menu_textfield
    @menu_textfield.text = "#{@cfg.data['username']}"
    @state = STATE_MENU
    @menu_page = MENU_SETTINGS
  end

  def init_menu()
    @menu_items = []
    add_menu_item("[c]onnect", Proc.new { connect_menu() })
    add_menu_item("settings", Proc.new { settings_menu() })
    add_menu_item("[q]uit", Proc.new { exit() })
  end

  def add_menu_item(name, callback)
    @menu_items.push([name, callback])
  end
end
