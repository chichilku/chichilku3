require 'socket'
require_relative '../share/network'
require_relative '../share/player'
require_relative '../share/map'

STATE_ERROR = -2
STATE_MENU = -1
STATE_OFFLINE = 0
STATE_CONNECTING = 1
STATE_DOWNLOADING = 2
STATE_INGAME = 3
STATE_REC_PLAYBACK = 4

# Networking part of the game clientside
class Client
  attr_reader :id, :state, :server_version, :map

  def initialize(console, cfg, gui)
    @id = nil
    @tick = 0
    @state = STATE_MENU
    @cfg = cfg
    @gui = gui

    @console = console
    @console.log "LOAD #{@s}"

    @s = nil # network socket (set in connect() method)

    @recording_ticks = []
    @recording_ticks_len = 0
    @recording_file = "autorec.txt"
    @is_recording = false

    @server_version = nil

    @map = nil

    # @force_send
    # used by client to send data regardless of what the gui
    # wanted to send
    @force_send = nil

    # state variables
    @req_playerlist = Time.now - 8

    # return values
    @players = []
    @flags = { skip: false, state: @state, gamestate: 'g',id: nil }
    @extra = nil # currently only used for download progress array
  end

  def reset()
    @id = nil
    @tick = 0
    @state = STATE_MENU
    @players = []
    @flags = { skip: false, state: @state, gamestate: 'g',id: nil }
  end

  def connect(ip, port)
    reset
    @s = TCPSocket.open(ip, port)
    @s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) # nagle's algorithm-
    @state = STATE_CONNECTING
    start_recording() if @cfg.data['autorecord']
  end

  def disconnect()
    return if @state == STATE_MENU
    return if @s.nil?

    @console.log "disconnecting from server."
    @s.close
    @s = nil
    reset
  end

  def load_recording(recording_file)
    recording_file = "#{@cfg.chichilku3_dir}recordings/#{recording_file}"
    @recording_ticks = []
    @tick = 0
    update_state(STATE_REC_PLAYBACK)
    File.readlines(recording_file).each do |data|
      @recording_ticks << data[0..-2] # cut off newline
    end
    # TODO: check if this .length lookup eats performance in ruby
    @recording_ticks_len = @recording_ticks.length
    @console.log "loaded recording containing #{@recording_ticks.size} ticks"
  end

  def start_recording()
    @recording_file = "autorec.txt"
    rec_file = "#{@cfg.chichilku3_dir}recordings/#{@recording_file}"
    @is_recording = true
    File.delete(rec_file) if File.exists? rec_file
  end

  def recording_record_tick(data)
    return unless @is_recording

    recording_file = "#{@cfg.chichilku3_dir}recordings/#{@recording_file}"
    IO.write(recording_file, data + "\n", mode: 'a')
  end

  def recording_playback_tick()
    if @recording_ticks_len <= @tick
      @console.log "finished playing back recording"
      update_state(STATE_MENU)
      return [[], @flags, nil]
    end
    data = @recording_ticks[@tick]
    if data.length != SERVER_PACKAGE_LEN
      @console.err "failed to parse recording data=#{data.length} server=#{SERVER_PACKAGE_LEN}"
      return nil
    end

    @tick += 1
    @flags[:skip] = false

    # save protocol and cut it off
    msg = handle_protocol(data[0].to_i, data[1], data[2..-1])
    [@players, @flags, msg, [@tick, @recording_ticks_len]]
  end

  def tick(client_data, protocol, tick)
    return nil if @state == STATE_MENU

    # sleep(1)
    @tick = tick
    @flags[:skip] = false

    # send data to the server
    send_data(client_data, protocol)

    # get data from the server + implicit return
    data = fetch_server_data
    return nil if data.nil?

    recording_record_tick(data)

    # save protocol and cut it off
    msg = handle_protocol(data[0].to_i, data[1], data[2..-1])
    [@players, @flags, msg, @extra]
  end

  private

  def update_state(state)
    @flags[:state] = state
    @state = state
  end

  def handle_protocol(protocol, p_status, data)
    @console.dbg "HANDLE PROTOCOL=#{protocol} status=#{p_status}"
    if protocol == 0 # error packet
      code = data[0..2]
      error_msg = data[3..-1]
      if code == NET_ERR_FULL
        @console.log "server is full."
      elsif code == NET_ERR_DISCONNECT
        @console.log "disconnected by server."
      elsif code == NET_ERR_KICK
        @console.log "kicked by server."
      elsif code == NET_ERR_BAN
        @console.log "banned by server."
      elsif code == NET_ERR_SERVER_OUTDATED
        @console.log "failed to connect to server: server is outdated."
        @console.log error_msg
      elsif code == NET_ERR_CLIENT_OUTDATED
        @console.log "failed to connect to server: your client is outdated."
      else
        @console.log "ERROR unkown error code code=#{code} data=#{data}"
        return
      end
      disconnect()
      @state = STATE_ERROR
      return [0, code, error_msg]
    elsif protocol == 1 # update package
      server_package_to_player_array(data)
    elsif protocol == 2 # id packet
      if @id.nil?
        id_packet(data)
      else
        @console.log "WARNING got unexpected id packet=#{data}"
      end
    elsif protocol == 3 # name packet
      protocol_names(data)
    elsif protocol == 4 # command respond
      @console.log "server respond: #{data}"
      return [1, data]
    elsif protocol == 5 # map info
      checksum = data[0..39]
      @map = Map.new(@console, @cfg, nil, method(:finished_download_callback), checksum)
    elsif protocol == 6 # map download init
      size = net_unpack_bigint(data[0..5])
      mapname = data[6..].strip
      @map.set_name(mapname)
      @map.set_size(size)
      accept = "0"
      if @map.has_map?
        @console.log "loading map name='#{mapname}'"
        finished_download_callback(@map.dl_path())
      else
        @console.log "downloading map name='#{mapname}' size=#{size} ..."
        update_state(STATE_DOWNLOADING)
        @map.prepare_download
        accept = "1"
      end
      @force_send = "5l#{@id.to_s(16)}#{accept}b641000"
    elsif protocol == 7 # map download chunk
      if @map.nil?
        @console.wrn "got unexpected map chunk from server (no map)"
        @force_send = "5l#{@id.to_s(16)}#{"0"}b641000"
      elsif @state != STATE_DOWNLOADING
        @console.wrn "got unexpected map chunk from server (wrong client state)"
        @force_send = "5l#{@id.to_s(16)}#{"0"}b641000"
      else
        @extra = [@map.download(data), @map.size]
      end
    else
      @console.log "ERROR unkown protocol=#{protocol} data='#{data}'"
    end
    nil
  end

  def send_data(data, protocol)
    if @id.nil?
      # request id has priority
      # resend after 100 ticks if no respond
      net_write("1l#{GAME_VERSION}XXXXX") if (@tick % 200).zero?
      return
    end

    # if no playerlist yet -> request one
    if @players == [] && @req_playerlist < Time.now - 4
      name = @cfg.data['username'].ljust(NAME_LEN, ' ')
      net_write("3l#{name}")
      @console.log('requesting a playerlist')
      @req_playerlist = Time.now
      return
    end

    unless @force_send.nil?
      net_write(@force_send)
      @force_send = nil
    end

    data = "#{protocol}l#{@id.to_s(16)}#{data.join('')}"
    net_write(data)
  end

  def set_id(id)
    if id > MAX_CLIENTS || id < 1
      @console.log "Errornous id=#{id}"
      return false
    end
    @id = id
    @console.log "Set ID=#{@id}"
    @flags[:id] = @id
    true
  end

  def grab_id(data)
    @console.log 'Trying to read id...'
    @playercount = net_unpack_int(data[0..1])
    id = data[2].to_i(16)
    set_id(id)
    update_state(STATE_INGAME) unless @state == STATE_REC_PLAYBACK
  end

  def id_packet(data)
    # protocol 2
    # the id protocol contains fresh client id
    # and server version
    grab_id(data)
    get_server_version(data)
  end

  def get_server_version(data)
    @server_version = data[4..7]
    @console.log "server version='#{@server_version}'"
  end

  def fetch_server_data
    server_data = save_read(@s, 3)
    return nil if server_data == ''

    if server_data[0] == "1"
      len = net_unpack_int(server_data[2]) * PLAYER_PACKAGE_LEN
      server_data += save_read(@s, len+1)
    else
      server_data += save_read(@s, SERVER_PACKAGE_LEN-3)
    end
    return nil if server_data == ''

    @console.dbg "recived data: #{server_data}"
    server_data
  end

  def net_write(data)
    if data.length != CLIENT_PACKAGE_LEN
      @console.log "ERROR wrong pack len: #{data.length}/#{CLIENT_PACKAGE_LEN} pck: #{data}"
      exit
    end
    @s.write(data)
    @console.dbg "sent: #{data}"
  end

  def finished_download_callback(map_dir)
    update_state(STATE_INGAME)
    @gui.load_background_image(map_dir)
    @map.load_gametiles(map_dir)
  end

  # TODO: add protocol class for this
  # TODO: protocol_names should create the player objects
  # AND: server_package_to_player_array should update the objs

  # playername package
  # And its dependencies:
  def protocol_names(data)
    #     3 0          00 00000 00 00000 00 00000 000
    playercount = net_unpack_int(data[0])
    @flags[:gamestate] = data[1]
    data = data[2..-1]
    p_strs = protocol_names_to_player_strs(playercount, data)
    protocol_names_strs_to_objs(p_strs)
  end

  def protocol_names_to_player_strs(used_slots, data)
    players = []
    used_slots.times do |index|
      size = NAME_LEN + 2 # id|score|name
      players[index] = data[index * size..index * size + size-1]
    end
    players
  end

  def protocol_names_strs_to_objs(player_strs)
    players = []
    player_strs.each do |player_str|
      id = player_str[0].to_i(16)
      score = net_unpack_int(player_str[1])
      name = player_str[2..-1].strip
      players << Player.new(id, 0, 0, score, name) unless id.zero?
    end
    # debug
    players.each { |p| @console.dbg "player=#{p.id} score=#{p.score} name='#{p.name}'" }
    @flags[:skip] = true # dont redner players at position zer0
    @players = players
  end

  # server_package_to_player_array
  # And its dependencies:
  def server_package_to_player_array(data)
    # /(?<count>\d{2})(?<player>(?<id>\d{2})(?<x>\d{3})(?<y>\d{3}))/
    # @console.log "data: #{data}"
    used_slots = net_unpack_int(data[0]) # save occupado slots
    # gamestate = data[1].to_i # save gamestate
    @flags[:gamestate] = data[1]
    # @console.log "gamestate: " + @flags[:gamestate]
    data = data[2..-1] # cut slots and gamestate off
    players = server_package_to_player_strs(used_slots, data)
    # @console.log "players: \n#{players}"
    player_strs_to_objects(players)
  end

  def server_package_to_player_strs(used_slots, data)
    players = []
    used_slots.times do |index|
      players[index] = data[index * PLAYER_PACKAGE_LEN..index * PLAYER_PACKAGE_LEN + PLAYER_PACKAGE_LEN-1]
    end
    players
  end

  def player_strs_to_objects(player_strs)
    players = []
    player_strs.each do |player_str|
      id = player_str[0].to_i(16)
      score = net_unpack_int(player_str[1])
      net_state = player_str[2]
      projR = player_str[3]
      projX = net_unpack_bigint(player_str[4..5])
      projY = net_unpack_bigint(player_str[6..7])
      aimX = net_unpack_bigint(player_str[8..9])
      aimY = net_unpack_bigint(player_str[10..11])
      x = net_unpack_bigint(player_str[12..13])
      y = net_unpack_bigint(player_str[14..15])
      # puts "'#{player_str}' id: #{id} x: #{x} '#{player_str[12..13]}' y: #{y} '#{player_str[14..15]}'"
      # players << Player.new(id, x, y) unless id.zero?

      @console.dbg "-- updt player id=#{id} score=#{score}--"
      p_index = Player.get_player_index_by_id(@players, id)
      @console.dbg "@players index=#{p_index}"
      @console.dbg "players: \n #{@players}"
      next if p_index.nil?

      @console.dbg "got player: #{@players[p_index]}"
      new_player = Player.update_player(@players, id, x, y, score, aimX, aimY)
      new_player.projectile.r = projR
      new_player.projectile.x = projX
      new_player.projectile.y = projY
      new_player.net_to_state(net_state)
      @players[Player.get_player_index_by_id(@players, id)] = new_player
    end
    # debug
    players.each { |p| @console.dbg "player=#{p.id} pos=#{p.x}/#{p.y}" }
    players
  end
end
