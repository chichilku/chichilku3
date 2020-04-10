require 'socket'

require_relative '../share/console'
require_relative '../share/network'
require_relative '../share/player'

require_relative 'gamelogic'
require_relative 'server_cfg'

$next_tick = Time.now

# ServerCore: should only contain the networking
# and no gamelogic
class ServerCore
  def initialize
    @players = []
    @clients = []
    @current_id = 0
    @tick = 0
    @last_alive_pck_by_client = Time.now
    @console = Console.new
    @cfg = ServerCfg.new(@console, "server.json")
    @gamelogic = GameLogic.new(@console)
    @global_pack = nil
  end

  def parse_client_version(data)
    return if data.nil?

    id = data[0].to_i
    version = data[1..-1]
    player = Player.get_player_by_id(@players, id)
    if player
      @console.log "name req id='#{id}' vrs='#{version}' name='#{player.name}'"
      player.set_version(version)
    else
      @console.log "error parsing version data=#{data}"
    end
  end

  def create_name_package(data)
    # protocol 3 name prot
    # also includes client version
    parse_client_version(data)
    #                      gamestate
    #                         |
    pck = "3l#{@players.count}g"
    # pck = format('3l%02d', @players.count) # old 2 digit player count
    @players.each do |p|
      pck += p.to_n_pck
      @console.dbg "pname='#{p.name}'"
    end
    pck.ljust(SERVER_PACKAGE_LEN, '0')
  end

  def get_free_id
    # TODO: do this smarter
    used_ids = @players.map{ |p| p.id }
    id = 0
    while id < MAX_CLIENTS do
      id += 1
      return id unless used_ids.include? id
    end
    -1
  end

  def add_player(name, ip)
    @current_id = get_free_id()
    return -1 if @current_id > MAX_CLIENTS || @current_id < 1

    @console.log "Added player id='#{@current_id}' ip='#{ip}'"
    @players << Player.new(@current_id, 0, nil, nil, name, ip)
    @current_id # implicit return
  end

  def delete_player(id)
    @console.log "Deleted player id='#{id}'"
    @players.delete(Player.get_player_by_id(@players, id))
  end

  def players_to_packet
    # old 2 digit player count
    # packet = @players.empty? ? '00' : format('%02d', @players.count)
    packet = @players.empty? ? '0' : @players.count.to_s
    packet += 'g' # gamestate
    @players.each do |player|
      packet += player.to_s
    end
    # fill with zeros if less than 3 players online
    packet.ljust(SERVER_PACKAGE_LEN - 2, '0') # implicit return
  end

  def update_pck(data, dt)
    id = data[0].to_i
    @console.dbg "got player with id: #{id}"
    @players = @gamelogic.handle_client_requests(data[1..-1], id, @players, dt)
    nil # defaults to normal update pck
  end

  def id_pck(data, ip)
    name = data[0..5]
    id = add_player(name, ip)
    if id == -1
      @console.log "'#{name}' failed to connect (server full)"
      # protocol 0 (error) code=404 slot not found
      return "0l#{NET_ERR_FULL}                       "
    end
    @console.log "id='#{id}' name='#{name}' joined the game"
    @global_pack = "true"
    # protocol 2 (id)
    format('2l00%02d0000000000000000000000', id).to_s
  end

  def command_package(data)
    id = data[0..1].to_i
    cmd = data[1..-1]
    @console.log "[chat] ID=#{id} command='#{cmd}'"
    msg = "server_recived_ur_cmd: #{cmd}"
    msg = msg.ljust(SERVER_PACKAGE_LEN - 2, '0')
    msg = msg[0..SERVER_PACKAGE_LEN - 3]
    "4l#{msg}"
  end

  def handle_protocol(protocol, p_status, data, ip, dt)
    @console.dbg "HANDLE PROTOCOL=#{protocol} status=#{p_status}"
    if protocol.zero? # error pck
      @console.log "Error pck=#{data}"
    elsif protocol == 1 # id pck
      return id_pck(data, ip)
    elsif protocol == 2 # update pck
      return update_pck(data, dt)
    elsif protocol == 3 # initial request names
      return create_name_package(data)
    elsif protocol == 4 # command
      return command_package(data)
    else
      @console.log "ERROR unkown protocol=#{protocol} data=#{data}"
    end
  end

  def handle_client_data(data, ip, dt)
    response = handle_protocol(data[0].to_i, data[1], data[2..-1], ip, dt)
    # the response is a direct respond to an protocol
    # everything above this could override important responds
    # like id assignment
    # every think that is after this guad case just overrides update pcks
    return response unless response.nil?

    if (@tick % 100).zero?
      # return '3l0301hello02x0x0x03hax0r000'
      return create_name_package(nil)
    end

    # some debug suff for class vars
    # if (@tick % 50).zero?
    #   puts ""
    #   @console.log "id=#{data[0].to_i} currentid=#{@current_id}"
    # end

    # if @global_pack.nil?
    #   @global_pack = nil
    #   @console.log "sending an global pck"
    #   return "5l#{players_to_packet}"
    # end

    # if error occurs or something unexpected
    # just send regular update pck
    # protocol 1 (update)
    "1l#{players_to_packet}" # implicit return
  end

  # TODO: this func and it dependencies should be new file
  # Handles each client
  def client_tick(cli, dt)
    client_data = save_read(cli, CLIENT_PACKAGE_LEN)
    if client_data == ''
      # diff = Time.now - @last_alive_pck_by_client
      # if (diff > MAX_TIMEOUT)
      #   @console.log "sombody timed out"
      # end
      return
    end

    @console.dbg "recv: #{client_data}"
    @last_alive_pck_by_client = Time.now
    port, ip = Socket.unpack_sockaddr_in(cli.getpeername)
    server_response = handle_client_data(client_data, ip, dt)
    # server_response = '1l03011001010220020203300303'
    net_write(server_response, cli)
  end

  def run
    server = TCPServer.open(@cfg.data['port'])
    server.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) # nagle's algorithm
    Thread.new do
      accept(server)
    end
    loop do
      diff = 0 # TODO: unused lmao traced it through the half source
      t = Time.now
      sleep $next_tick - t if $next_tick > t
      @tick += 1
      $next_tick = Time.now + MAX_TICK_SPEED
      @clients.each do |client|
        begin
          client_tick(client, diff)
        rescue Errno::ECONNRESET
          client_id = @clients.index(client) + 1 # client ids start from 1
          @console.log "player left the game (id=#{client_id})."
          client.close
          delete_player(client_id)
          @clients.delete(client)
          @current_id -= 1
        end
      end
    end
  end

  private

  def accept(server)
    Socket.accept_loop(server) do |client|
      @clients << client
      @console.log "client joined. clients connected: #{@clients}"
    end
  end

  def net_write(data, cli)
    if data.length != SERVER_PACKAGE_LEN
      @console.log "ERROR pack len: #{data.length}/#{SERVER_PACKAGE_LEN} pck: #{data}"
      exit
    end
    @console.dbg("sending: #{data}")
    cli.write(data)
  end
end

srv = ServerCore.new
srv.run
