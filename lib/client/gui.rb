require 'gosu'
require_relative 'client'
require_relative '../external/gosu/text'
require_relative 'scoreboard'
require_relative '../share/console'
require_relative '../share/player'
require_relative 'keys'

MENU_MAIN = 0
MENU_CONNECT = 1
MENU_USERNAME = 2

MOUSE_RADIUS = 200

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
    self.caption = 'chichilku3'
    self.fullscreen = true if cfg.data['fullscreen']
    # images
    @crosshair = Gosu::Image.new(img("crosshair128x128.png"))
    @background_image = nil
    @connecting_image = Gosu::Image.new(img("connecting1024x512.png"))
    @menu_image = Gosu::Image.new(img("menu1920x1080.png"))
    @arrow_image = Gosu::Image.new(img("arrow64.png"))
    @stick_arm_images = []
    @stick_arm_images << Gosu::Image.new(img("stick128/arm64/arm0.png"))
    @stick_arm_images << Gosu::Image.new(img("stick128/arm64/arm1.png"))
    @stick_arm_images << Gosu::Image.new(img("stick128/arm64/arm2.png"))
    @stick_arm_images << Gosu::Image.new(img("stick128/arm64/arm3.png"))
    @stick_crouching = []
    @stick_crouching << Gosu::Image.new(img("stick128/stick_crouching0.png"))
    @stick_crouching << Gosu::Image.new(img("stick128/stick_crouching1.png"))
    @stick_crouching << Gosu::Image.new(img("stick128/stick_crouching2.png"))
    @stick_crouching << Gosu::Image.new(img("stick128/stick_crouching3.png"))
    @stick_crouching << Gosu::Image.new(img("stick128/stick_crouching4.png"))
    @stick_crouching << Gosu::Image.new(img("stick128/stick_crouching5.png"))
    @stick_images = []
    @stick_images << Gosu::Image.new(img("stick128/noarms/stick0.png"))
    @stick_images << Gosu::Image.new(img("stick128/noarms/stick1.png"))
    @stick_images << Gosu::Image.new(img("stick128/noarms/stick2.png"))
    @stick_images << Gosu::Image.new(img("stick128/noarms/stick3.png"))
    @stick_images << Gosu::Image.new(img("stick128/noarms/stick4.png"))
    @bow_images = []
    @bow_images << Gosu::Image.new(img("bow64/bow0.png"))
    @bow_images << Gosu::Image.new(img("bow64/bow1.png"))
    @bow_images << Gosu::Image.new(img("bow64/bow2.png"))
    @bow_images << Gosu::Image.new(img("bow64/bow3.png"))
    # TODO: add arms back in if no bow is in use
    # @stick_images << Gosu::Image.new(img("stick128/stick0.png"))
    # @stick_images << Gosu::Image.new(img("stick128/stick1.png"))
    # @stick_images << Gosu::Image.new(img("stick128/stick2.png"))
    # @stick_images << Gosu::Image.new(img("stick128/stick3.png"))
    # @stick_images << Gosu::Image.new(img("stick128/stick4.png"))
    # @stick_images << Gosu::Image.new(img("stick128/stick5.png"))
    @x = 0
    @y = 0
    @players = []
    @cfg = cfg
    @tick = 0
    @console = Console.new
    @net_client = Client.new(@console, @cfg, self)
    @net_err = nil
    @state = @net_client.state
    @menu_page = MENU_MAIN
    @font = Gosu::Font.new(20)
    @is_debug = false
    @is_dbg_grid = false
    @is_chat = false
    @is_scoreboard = false
    @chat_msg = "" # what we type
    @server_chat_msg = "" # what we get from server
    @chat_show_time = 4
    @server_chat_recv = Time.now - @chat_show_time
    @last_key = nil
    @events = {
      :blood => []
    }
    @menu_items = []
    @selected_menu_item = 0
    @menu_textfield = TextField.new(self, 60, 200)
    @demo_ticks = [0,0]
    @download_progress = [0,0]
    # @chat_inp_stream = nil #TextInput.new
    # @chat_inp_stream.text # didnt get it working <--- nobo xd
    
    @last_pressed_button = {}

    # depreciated ._.
    # @con_msg = Gosu::Image.from_text(self, "connecting to #{@cfg.data['ip']}:#{@cfg.data['port']}...", Gosu.default_font_name, 45)
    init_menu()

    if ARGV.length > 0
      port = ARGV.length > 1 ? ARGV[1].to_i : 9900
      connect(ARGV[0], port)
    end
  end

  def img(path)
    File.join(File.dirname(__FILE__), "../../lib/client/img/", path)
  end

  def load_background_image(map_path)
    bg_path =  File.join(map_path, "background.png")
    @console.log "loading background image '#{bg_path}' ..."
    @background_image = Gosu::Image.new(bg_path)
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
      elsif @menu_page == MENU_USERNAME
        enter_name_tick
      else
        menu_tick
      end
    elsif @state == STATE_ERROR
      if button_down?(Gosu::KB_ESCAPE)
        @state = STATE_MENU
        @net_client.disconnect
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
        connect(@cfg.data['ip'], @cfg.data['port'])
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
        @net_client.disconnect
      elsif @state == STATE_INGAME
        @state = STATE_MENU
        @net_client.disconnect
        return
      elsif @state == STATE_REC_PLAYBACK
        @state = STATE_MENU
        return
      end
    end
    net_request = '0000'.split('')
    net_request << "!!!!"
    protocol = 2

    if @is_chat
      msg = chat_tick
      if !msg.nil?
        # @console.dbg "rawmsg: #{msg}"
        msg = msg.ljust(8, '0')
        net_request = msg[0..CMD_LEN].split('')
        # @console.dbg "prepedmsg: #{net_request}"
        protocol = 4
      end
    else
      net_request[0] = '0' # space for more
      if button_down?(KEY_S)
        net_request[0] = '1'
      end
      if button_down?(KEY_A)
        net_request[1] = 'l'
      end
      if button_down?(KEY_D)
        net_request[1] = 'r'
      end
      if button_down?(Gosu::KB_SPACE)
        net_request[2] = '1'
      end
      if button_press?(KEY_M)
        @is_debug = !@is_debug
      end
      if button_press?(KEY_G) && @is_debug
        @is_dbg_grid = !@is_dbg_grid
      end
      if button_down?(KEY_T)
        @last_key = KEY_T
        @is_chat = true
        @chat_msg = ""
      end
      if button_down?(Gosu::MsLeft)
        net_request[3] = '1'
      end
      # TODO: check for active window
      # do not leak mouse movement in other applications than chichilku3
      net_request[4] = net_pack_bigint(self.mouse_x.to_i.clamp(0, 8834), 2)
      net_request[5] = net_pack_bigint(self.mouse_y.to_i.clamp(0, 8834), 2)
      @is_scoreboard = button_down?(Gosu::KB_TAB)
    end

    if @state == STATE_REC_PLAYBACK
      net_data = @net_client.recording_playback_tick()
      @demo_ticks = net_data[3] unless net_data.nil?
    else
      # Networking
      begin
        net_data = @net_client.tick(net_request, protocol, @tick)
      rescue Errno::ECONNRESET, Errno::EPIPE
        net_data = [@players, @flags, [0, NET_ERR_DISCONNECT, "connection to server lost"]]
        @net_client.disconnect
      end
    end
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
    if @state == STATE_DOWNLOADING
      @download_progress = net_data[3] unless net_data[3].nil?
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
    @menu_image.draw(0, 0, 0, UI_SCALE, UI_SCALE)
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

  def event_blood(x, y)
    splashes = []
    20.times do
      splashes << [x, y, rand(6) - 3, rand(6) - 10, rand(1..6), rand(1..6)]
    end
    @events[:blood] << [
      x,
      y,
      0,
      splashes
    ]
  end

  def draw_events
    bloods = []
    @events[:blood].each do |blood|
      x = blood[0]
      y = blood[1]
      tick = blood[2]
      splashes = blood[3]
      new_splashes = []
      splashes.each do |splash|
        sx = splash[0]
        sy = splash[1]
        dx = splash[2]
        dy = splash[3]
        sw = splash[4]
        sh = splash[5]
        sx += dx
        sy += dy
        dy += 1 # gravity
        draw_rect(sx, sy, sw, sh, 0xAAFF0000)
        new_splashes << [sx, sy, dx, dy, sw, sh]
      end
      unless tick > 200
        bloods << [x, y, tick + 1, new_splashes]
      end
    end
    @events[:blood] = bloods
  end

  def draw_debug(x, y, s=1)
    return unless @is_debug

    draw_rect(x, y, 4*s, 4*s, 0xFFFF0000, 1)
    draw_rect(x+1*s, y+1*s, 2*s, 2*s, 0xFF00FF00, 1)
  end

  def draw
    # draw_quad(0, 0, 0xffff8888, WINDOW_SIZE_X, WINDOW_SIZE_Y, 0xffffffff, 0, 0, 0xffffffff, WINDOW_SIZE_X, WINDOW_SIZE_Y, 0xffffffff, 0)
    if @state == STATE_MENU
      if @menu_page == MENU_CONNECT
        @connecting_image.draw(0, 0, 0)
        @font.draw_text("Enter server ip", 20, 20, 0, 5, 5)
        @menu_textfield.draw(0)
      elsif @menu_page == MENU_USERNAME
        @connecting_image.draw(0, 0, 0)
        @font.draw_text("Choose a username", 20, 20, 0, 5, 5)
        @menu_textfield.draw(0)
      else
        draw_main_menu()
      end
    elsif @state == STATE_CONNECTING
      @connecting_image.draw(0, 0, 0)
      @font.draw_text("connecting to #{@cfg.data['ip']}:#{@cfg.data['port']}...", 20, 20, 0, 3, 3)
    elsif @state == STATE_DOWNLOADING
      @connecting_image.draw(0, 0, 0)
      @font.draw_text("downloading map #{@download_progress[0]} / #{@download_progress[1]} ...", 20, 20, 0, 3, 3)
    elsif @state == STATE_INGAME || @state == STATE_REC_PLAYBACK
      @background_image.draw(0, 0, 0)
      @crosshair.draw(self.mouse_x-16, self.mouse_y-16, 0, 0.25, 0.25)
      # useless mouse trap
      # since its buggo and your character moves maybe keep it free
      # mouse players should go fullscreen
      # self.mouse_x = (WINDOW_SIZE_X / 2) + MOUSE_RADIUS - 1 if self.mouse_x > (WINDOW_SIZE_X / 2) + MOUSE_RADIUS
      # self.mouse_x = (WINDOW_SIZE_X / 2) - MOUSE_RADIUS + 1 if self.mouse_x < (WINDOW_SIZE_X / 2) - MOUSE_RADIUS
      # self.mouse_y = (WINDOW_SIZE_Y / 2) + MOUSE_RADIUS - 1 if self.mouse_y > (WINDOW_SIZE_Y / 2) + MOUSE_RADIUS
      # self.mouse_y = (WINDOW_SIZE_Y / 2) - MOUSE_RADIUS + 1 if self.mouse_y < (WINDOW_SIZE_Y / 2) - MOUSE_RADIUS
      @players.each do |player|
        event_blood(player.x + (player.w/2), player.y + (player.h/2)) if player.state[:bleeding]
        player.draw_tick
        @console.dbg "drawing player id=#{player.id} pos=#{player.x}/#{player.y}"
        # draw_rect(player.x, player.y, TILE_SIZE, TILE_SIZE, Gosu::Color::WHITE)
        if player.state[:crouching]
          @stick_crouching[player.img_index].draw(player.x, player.y, 0, 0.5, 0.5)
        else
          @stick_images[player.img_index].draw(player.x, player.y, 0, 0.5, 0.5)
          x = player.aimX - player.x
          y = player.aimY - player.y
          rot = Math.atan2(x, y) * 180 / Math::PI * -1 + 90 * -1
          rot2 = Math.atan2(x, y) * 180 / Math::PI * -1 + 270 * -1
          stick_center_x = player.x + TILE_SIZE/4
          stick_center_y = player.y + TILE_SIZE/2
          d = -8
          d += player.state[:fire] * 3
          arr_x = stick_center_x + (d * Math.cos((rot2 + 180) / 180 * Math::PI))
          arr_y = stick_center_y + (d * Math.sin((rot2 + 180) / 180 * Math::PI))
          @bow_images[player.state[:fire]].draw_rot(stick_center_x, stick_center_y, 0, rot, 0.5, 0.5, 0.5, 0.5)
          @stick_arm_images[player.state[:fire]].draw_rot(stick_center_x, stick_center_y, 0, rot, 0.5, 0.5, 0.5, 0.5)
          if player.projectile.x == 0 and player.projectile.y == 0
            @arrow_image.draw_rot(arr_x, arr_y, 0, rot2, 0.5, 0.5, 0.5, 0.5)
          end
          if @is_debug
            draw_debug(arr_x, arr_y, 2)
            draw_debug(stick_center_x, stick_center_y, 1)
            draw_line(arr_x, arr_y, 0xFFFF0000, stick_center_x, stick_center_y, 0xFF000000)
            @font.draw_text("rot=#{rot.to_i} rot2=#{rot2.to_i}", player.x - 60, player.y - 100, 0, 1, 1, 0xFF000000)
            @font.draw_text("d=#{d} (#{stick_center_x}/#{stick_center_y}) -> (#{arr_x.to_i}/#{arr_y.to_i})", player.x - 80, player.y - 80, 0, 1, 1, 0xFF000000)
          end
        end
        unless player.projectile.x == 0 or player.projectile.y == 0
          rot = player.projectile.r.to_i * 45
          @arrow_image.draw_rot(player.projectile.x, player.projectile.y, 0, rot, 0.5, 0.5, 0.5, 0.5)
        end
        if @is_debug # print id
          # aim
          draw_rect(player.aimX - 2, player.aimY - 16, 4, 32, 0xCC33FF33)
          draw_rect(player.aimX - 16, player.aimY - 2, 32, 4, 0xCC33FF33)
          draw_rect(player.aimX, player.aimY - 15, 1, 30, 0xAA000000)
          draw_rect(player.aimX - 15, player.aimY, 30, 1, 0xAA000000)
          # text background
          draw_rect(player.x - 2, player.y - 60, 32, 20, 0xAA000000)
          @font.draw_text("#{player.id}:#{player.score}", player.x, player.y - 60, 0, 1, 1)
          # @font.draw_text("#{player.id}:#{player.img_index}", player.x, player.y - TILE_SIZE * 2, 0, 1, 1)
          if player.state[:crouching]
            draw_rect(player.x, player.y, TILE_SIZE, TILE_SIZE/2, 0xAA00EE00)
          else
            draw_rect(player.x, player.y, TILE_SIZE/2, TILE_SIZE, 0xAA00EE00)
          end
          unless player.projectile.x == 0 or player.projectile.y == 0
            draw_rect(player.projectile.x, player.projectile.y, player.projectile.w, player.projectile.h, 0xAA00EE00)
          end
        end
        @font.draw_text(player.name, player.x - (TILE_SIZE/6), player.y - TILE_SIZE / 2, 0, 1, 1, 0xff_000000)
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
        unless player.nil?
          draw_rect(5, 10, 290, 85, 0xAA000000)
          @font.draw_text("Press m to deactivate debug mode", 10, 10, 0, 1, 1)
          @font.draw_text("x: #{player.x} y: #{player.y}", 10, 30, 0, 1, 1)
          @font.draw_text("aimX: #{player.aimX} aimY: #{player.aimY}", 10, 45, 0, 1, 1)
          @font.draw_text("gamestate: #{@flags[:gamestate]}", 10, 60, 0 , 1, 1)
          @font.draw_text("server version: #{@net_client.server_version}", 10, 75, 0 , 1, 1)
          # thats useless because collide/delta speed is not sent over the network
          # @font.draw_text("dx: #{player.dx} dy: #{player.dy}", 10, 50, 0, 1, 1)
          # @font.draw_text(player.collide_string, 10, 70, 0, 1, 1)
        end

        if @is_dbg_grid
          (1..MAP_WIDTH).each do |gx|
            draw_rect(gx * TILE_SIZE, 0, 1, WINDOW_SIZE_Y, 0xAA00EE00)
          end
          (1..MAP_HEIGHT).each do |gy|
            draw_rect(0, gy * TILE_SIZE, WINDOW_SIZE_X, 1, 0xAA00EE00)
          end
          # gametiles
          if @net_client.map && @net_client.map.ready
            (0..(MAP_HEIGHT-1)).each do |gy|
              (0..(MAP_WIDTH-1)).each do |gx|
                if @net_client.map.is_collision?(gx, gy)
                  draw_rect(gx * TILE_SIZE, gy * TILE_SIZE, TILE_SIZE, TILE_SIZE, 0xAA00EE00)
                elsif @net_client.map.is_death?(gx, gy)
                  draw_rect(gx * TILE_SIZE, gy * TILE_SIZE, TILE_SIZE, TILE_SIZE, 0xAAEE0000)
                end
              end
            end
          end
        end
      end

      draw_events()

      if @is_scoreboard
        draw_scoreboard(WINDOW_SIZE_X, WINDOW_SIZE_Y, @players, @font, @is_debug)
      end
      if @state == STATE_REC_PLAYBACK && !(@demo_ticks.nil?)
        @font.draw_text("#{@demo_ticks[0]}/#{@demo_ticks[1]}", 10, WINDOW_SIZE_Y - 20, 0)
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

  def connect(ip, port)
    @console.log "connecting to server '#{ip}:#{port}' ..."
    begin
      @net_client.connect(ip, port)
      @state = STATE_CONNECTING;
      @menu_page = MENU_MAIN
    rescue Errno::ECONNREFUSED
      @state = STATE_ERROR
      @menu_page = MENU_MAIN
      @net_err = [NET_ERR_DISCONNECT, "connection refused"]
      @net_client.disconnect
    end
  end

  def connect_menu()
    @last_key = Gosu::KB_RETURN
    self.text_input = @menu_textfield
    @menu_textfield.text = "#{@cfg.data['ip']}:#{@cfg.data['port']}"
    @state = STATE_MENU
    @menu_page = MENU_CONNECT
  end

  def username_page()
    @last_key = Gosu::KB_RETURN
    self.text_input = @menu_textfield
    @menu_textfield.text = "#{@cfg.data['username']}"
    @state = STATE_MENU
    @menu_page = MENU_USERNAME
  end

  def toggle_fullscreen()
    if @cfg.data['fullscreen']
      @cfg.data['fullscreen'] = self.fullscreen = false
    else
      @cfg.data['fullscreen'] = self.fullscreen = true
    end
  end

  def play_recording()
    @net_client.load_recording('autorec.txt')
    @state = STATE_REC_PLAYBACK
  end

  def init_menu()
    @menu_items = []
    add_menu_item("[c]onnect", Proc.new { connect_menu() })
    add_menu_item("username", Proc.new { username_page() })
    add_menu_item("fullscreen", Proc.new { toggle_fullscreen() })
    add_menu_item("recording", Proc.new { play_recording() })
    add_menu_item("[q]uit", Proc.new { exit() })
  end

  def add_menu_item(name, callback)
    @menu_items.push([name, callback])
  end
end
