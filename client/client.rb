require 'socket'
require_relative '../share/network'
require_relative '../share/player'

STATE_OFFLINE = 0
STATE_CONNECTING = 1
STATE_INGAME = 2

# Networking part of the game clientside
class Client
  attr_reader :id
  def initialize(console, cfg)
    @id = nil
    @tick = 0
    @state = STATE_OFFLINE
    @cfg = cfg

    @console = console
    @s = TCPSocket.open(@cfg.data['ip'], @cfg.data['port'])
    @console.log "LOAD #{@s}"

    # return values
    @players = []
    @flags = { skip: false, state: @state, id: nil }
  end

  def tick(client_data, protocol, tick)
    # sleep(1)
    @tick = tick
    @flags[:skip] = false

    # send data to the server
    send_data(client_data, protocol)

    # get data from the server + implicit return
    data = fetch_server_data
    return nil if data.nil?

    # only process the long packages and ignore ip packages here
    return nil if data.length != SERVER_PACKAGE_LEN

    # save protocol and cut it off
    handle_protocol(data[0].to_i, data[1], data[2..-1])
    [@players, @flags]
  end

  private

  def update_state(state)
    @flags[:state] = state
    @state = state
  end

  def handle_protocol(protocol, p_status, data)
    @console.dbg "HANDLE PROTOCOL=#{protocol} status=#{p_status}"
    if protocol == 1 # update package
      server_package_to_player_array(data)
    elsif protocol == 2 # id packet
      if @id.nil?
        grab_id(data)
      else
        @console.log "WARNING got unexpected id packet=#{data}"
      end
    elsif protocol == 3 # name packet
      protocol_names(data)
    elsif protocol == 4 # command respond
      @console.log "server respond: #{data}"
    else
      @console.log "ERROR unkown protocol=#{protocol} data=#{data}"
    end
  end

  def send_data(data, protocol)
    if @id.nil?
      # request id has priority
      # resend after 100 ticks if no respond
      name = @cfg.data['username'].ljust(5, '-')
      net_write("1l#{name}") if (@tick % 200).zero?
      return
    end

    # if no playerlist yet -> request one
    if @players == []
      net_write('3l00000')
      @console.log('requesting a playerlist')
      return
    end

    # prefix data with id
    # prot 2 = update pck
    # prot updated to dynamic becuase we now also send cmds
    data = format("#{protocol}l%02d#{data.join('')}", @id)
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
    @playercount = data[0..1]
    id = data[2..3].to_i
    set_id(id)
    update_state(STATE_INGAME)
  end

  def fetch_server_data
    server_data = save_read(@s, SERVER_PACKAGE_LEN)
    return nil if server_data == ''

    @console.dbg "recived data: #{server_data}"
    server_data
  end

  def net_write(data)
    if data.length != CLIENT_PACKAGE_LEN
      @console.log "ERROR wrong pack len: #{data.length} pck: #{data}"
      exit
    end
    @s.write(data)
    @console.dbg "sent: #{data}"
  end

  # TODO: add protocol class for this
  # TODO: protocol_names should create the player objects
  # AND: server_package_to_player_array should update the objs

  # playername package
  # And its dependencies:
  def protocol_names(data)
    #     03          00 00000 00 00000 00 00000 000
    playercount = data[0..1].to_i
    data = data[2..-1]
    p_strs = protocol_names_to_player_strs(playercount, data)
    protocol_names_strs_to_objs(p_strs)
  end

  def protocol_names_to_player_strs(slots, data)
    players = []
    slots.times do |index|
      players[index] = data[index * 7..index * 7 + 6]
    end
    players
  end

  def protocol_names_strs_to_objs(player_strs)
    players = []
    player_strs.each do |player_str|
      id = player_str[0..1].to_i
      name = player_str[2..-1]
      players << Player.new(id, 0, 0, name) unless id.zero?
    end
    # debug
    players.each { |p| @console.dbg "player=#{p.id} name=#{p.name}" }
    @flags[:skip] = true # dont redner players at position zer0
    @players = players
  end

  # server_package_to_player_array
  # And its dependencies:
  def server_package_to_player_array(data)
    # /(?<count>\d{2})(?<player>(?<id>\d{2})(?<x>\d{3})(?<y>\d{3}))/
    # @console.log "data: #{data}"
    slots = data[0..1].to_i # save slots
    data = data[2..-1] # cut slots off
    players = server_package_to_player_strs(slots, data)
    # @console.log "players: \n#{players}"
    player_strs_to_objects(players)
  end

  def server_package_to_player_strs(slots, data)
    players = []
    slots.times do |index|
      players[index] = data[index * 8..index * 8 + 7]
    end
    players
  end

  def player_strs_to_objects(player_strs)
    players = []
    player_strs.each do |player_str|
      id = player_str[0..1].to_i
      x = player_str[2..4].to_i
      y = player_str[5..7].to_i
      # puts "id: #{id} x: #{x} y: #{y}"
      # players << Player.new(id, x, y) unless id.zero?

      @console.dbg "-- updt player id=#{id} --"
      p_index = Player.get_player_index_by_id(@players, id)
      @console.dbg "@players index=#{p_index}"
      @console.dbg "players: \n #{@players}"
      next if p_index.nil?

      @console.dbg "got player: #{@players[p_index]}"
      new_player = Player.update_player(@players, id, x, y)
      @players[Player.get_player_index_by_id(@players, id)] = new_player
    end
    # debug
    players.each { |p| @console.dbg "player=#{p.id} pos=#{p.x}/#{p.y}" }
    players
  end
end
