require 'socket'

require_relative '../share/console'
require_relative '../share/network'
require_relative '../share/player'
require_relative '../share/map'

require_relative 'gamelogic'
require_relative 'server_cfg'

$next_tick = Time.now

NET_CLIENT = 0
PLAYER_ID = 1

# ServerCore: should only contain the networking
# and no gamelogic
class ServerCore
  def initialize
    # single dimension array holding player objects
    @players = []
    # multi dimensional array
    # 0 - client network socket
    # 1 - player id
    @clients = []
    @current_id = 0
    @bans = {}
    @tick = 0
    @last_alive_pck_by_client = Time.now
    @console = Console.new
    @cfg = ServerCfg.new(@console, "server.json")
    @gamelogic = GameLogic.new(@console)

    @cfg.data['map'] = 'battle' if @cfg.data['map'] == ""
    @map = Map.new(@console, @cfg, @cfg.data['map'])
    @map.prepare_upload
  end

  def parse_client_version(data)
    return if data.nil?

    id = data[0].to_i(16)
    version = data[1..4]
    player = Player.get_player_by_id(@players, id)
    if player
      @console.dbg "[NAME-REQUEST] ID='#{id}' version='#{version}' name='#{player.name}'"
      player.set_version(version)
    else
      @console.err "failed to parse version data=#{data}"
    end
    player
  end

  def create_name_package(data, client)
    if !client.nil? && !data.nil?
      player = Player.get_player_by_id(@players, client[PLAYER_ID])
      if player.nil?
        port, ip = Socket.unpack_sockaddr_in(client[NET_CLIENT].getpeername)
        @console.wrn "IP=#{ip}:#{port} tried to get a name pack (without player)"
        return
      end
      player.set_name(data.strip.gsub(/[^a-zA-Z0-9_]/, '_'))
      @gamelogic.on_player_connect(client, @players)
    end

    # protocol 3 name prot
    #                                   gamestate
    #                                       |
    pck = "3l#{net_pack_int(@players.count)}g"
    @players.each do |p|
      pck += p.to_n_pck
    end
    pck.ljust(SERVER_PACKAGE_LEN, '0')
  end

  def get_free_id
    # TODO: do this smarter
    used_ids = @clients.map{ |c| c[1] }
    id = 0
    while id < MAX_CLIENTS do
      id += 1
      return id unless used_ids.include? id
    end
    -1
  end

  def add_player(name, version, client, ip)
    @current_id = get_free_id()
    return -1 if @current_id > MAX_CLIENTS || @current_id < 1

    @console.dbg "[NEW PLAYER] IP='#{ip}' ID='#{@current_id}' version='#{version}'"
    @players << Player.new(@current_id, 0, nil, nil, name, version, ip)
    client[PLAYER_ID] = @current_id
    @current_id # implicit return
  end

  def delete_player(id)
    @players.delete(Player.get_player_by_id(@players, id))
  end

  def players_to_packet
    # player count
    packet = net_pack_int(@players.empty? ? 0 : @players.count)
    packet += 'g' # gamestate
    @players.each do |player|
      packet += player.to_s
    end
    packet
  end

  def update_pck(data, dt)
    id = data[0].to_i(16)
    @console.dbg "[UPDATE] got player with id: #{id}"
    @players = @gamelogic.handle_client_requests(data[1..-1], id, @players, dt)
    nil # defaults to normal update pck
  end

  def map_info_pck()
    "5l#{@map.checksum}".ljust(SERVER_PACKAGE_LEN, ' ')
  end

  def map_dl_init_pck()
    size = net_pack_bigint(@map.size, 6)
    name = @map.name
    "6l#{size}#{name}".ljust(SERVER_PACKAGE_LEN, ' ')
  end

  def map_dl_chunk_pck(player)
    size = SERVER_PACKAGE_LEN - 2
    map_chunk = @map.get_data(player.map_download, size)
    player.map_download += size
    "7l#{map_chunk}"
  end

  def id_pck(data, client, ip)
    if num_ip_connected(ip) > @cfg.data['max_clients_per_ip']
      disconnect_client(client, "0l#{NET_ERR_DISCONNECT}too many clients per ip                        ")
      return
    end
    player_version = data[0..3]
    id = add_player("(connecting)", player_version, client, ip)
    if id == -1
      @console.log "IP='#{ip}' failed to connect (server full)"
      # protocol 0 (error) code=404 slot not found
      return "0l#{NET_ERR_FULL}                       "
    end
    if player_version.to_i < GAME_VERSION.to_i
      @console.log "IP='#{ip}' failed to connect (client too old '#{player_version}' < '#{GAME_VERSION}')"
      return "0l#{NET_ERR_CLIENT_OUTDATED}#{GAME_VERSION}".ljust(SERVER_PACKAGE_LEN, ' ')
    elsif player_version.to_i > GAME_VERSION.to_i
      @console.log "IP='#{ip}' failed to connect (client too new '#{player_version}' < '#{GAME_VERSION}')"
      return "0l#{NET_ERR_SERVER_OUTDATED}#{GAME_VERSION}".ljust(SERVER_PACKAGE_LEN, ' ')
    end
    @console.dbg "[ID-PACKAGE] ID='#{id}' IP='#{ip}'"
    # protocol 2 (id)
    "2l#{net_pack_int(@players.count)}#{net_pack_int(MAX_CLIENTS)}#{id.to_s(16)}X#{GAME_VERSION}".ljust(SERVER_PACKAGE_LEN, '0')
  end

  def command_package(data, client)
    id = data[0..1].to_i(16)
    cmd = data[1..-1]
    @console.log "[chat] ID=#{id} command='#{cmd}'"
    msg = "server_recived_cmd: #{cmd}"
    msg = msg.ljust(SERVER_PACKAGE_LEN - 2, '0')
    msg = msg[0..SERVER_PACKAGE_LEN - CMD_LEN]
    if cmd == "test"
      # return "0l#{NET_ERR_DISCONNECT}    SAMPLE MESSAGE     "
      msg = "id=#{client[PLAYER_ID]}"
    end
    msg = msg.ljust(SERVER_PACKAGE_LEN - 2, ' ')
    msg = msg[0..SERVER_PACKAGE_LEN - 2]
    # protocol 4 (chat command)
    "4l#{msg}"
  end

  def handle_protocol(client, protocol, p_status, data, ip, dt)
    @console.dbg "[PROTOCOL] protocol=#{protocol} status=#{p_status}"
    if protocol.zero? # error pck
      @console.err "Error pck=#{data}"
    elsif protocol == 1 # id pck
      return id_pck(data, client, ip)
    elsif protocol == 3 # initial request names
      return create_name_package(data, client)
    else
      if data.nil?
        @console.err "IP=#{ip} invalid data"
        return
      end
      # all other types require id
      id = data[0].to_i(16)
      if id != client[PLAYER_ID]
        @console.wrn "id=#{client[PLAYER_ID]} tried to spoof id=#{id} ip=#{ip}"
        @console.wrn data
        disconnect_client(client, "0l#{NET_ERR_DISCONNECT}invalid player id                              ")
        return nil
      end
      if protocol == 2 # update pck
        return update_pck(data, dt) if @map.nil?

        player = Player.get_player_by_id(@players, id)
        if player.map_download == -2
          player.map_download = -1
          return map_info_pck()
        elsif player.map_download == -1
          # set state to -3 which stops sending
          # any further information
          # wait for the client to respond
          player.map_download = -3
          return map_dl_init_pck()
        elsif player.map_download < @map.size() && player.map_download >= 0
          return map_dl_chunk_pck(player)
        else
          return update_pck(data, dt)
        end
      elsif protocol == 4 # command
        return command_package(data, client)
      elsif protocol == 5 # map info response
        return update_pck(data, dt) if @map.nil?

        player = Player.get_player_by_id(@players, id)
        if data[1] == "1"
          player.map_download = 0
          @console.log "player started map download"
          return map_dl_chunk_pck(player)
        else
          @console.log "player rejected map download"
          player.map_download = @map.size
          return update_pck(data, dt)
        end
      else
        @console.err "IP=#{ip} unkown protocol=#{protocol} data=#{data}"
      end
    end
  end

  def handle_client_data(client, data, ip, dt)
    response = handle_protocol(client, data[0].to_i, data[1], data[2..-1], ip, dt)
    # the response is a direct respond to an protocol
    # everything above this could override important responds
    # like id assignment
    # everything that is after this guard case just overrides update pcks
    return response unless response.nil?

    if (@tick % 100).zero?
      return create_name_package(nil, nil)
    end

    # if error occurs or something unexpected
    # just send regular update pck
    # protocol 1 (update)
    "1l#{players_to_packet}"
  end

  # Handles each client
  def client_tick(cli, dt)
    client_data = save_read(cli[NET_CLIENT], CLIENT_PACKAGE_LEN)
    if client_data == ''
      # diff = Time.now - @last_alive_pck_by_client
      # if (diff > MAX_TIMEOUT)
      #   @console.log "sombody timed out"
      # end
      return
    end

    @last_alive_pck_by_client = Time.now
    port, ip = Socket.unpack_sockaddr_in(cli[NET_CLIENT].getpeername)
    server_response = handle_client_data(cli, client_data, ip, dt)
    pck_type = server_response[0]
    if pck_type == SERVER_PCK_TYPE[:error]
      disconnect_client(cli, server_response)
    else
      net_write(server_response, cli[NET_CLIENT])
    end
  end

  def disconnect_client(client, server_response = nil)
    player_id = client[PLAYER_ID]
    @gamelogic.on_player_disconnect(client, @players)
    @console.dbg "client disconnected.#{" (" + server_response + ")" unless server_response.nil?}"
    net_write(server_response, client[NET_CLIENT]) unless server_response.nil?
    client[NET_CLIENT].close
    delete_player(player_id)
    @clients.delete(client)
    @current_id -= 1
  end

  def client_by_playerid(player_id)
    @clients.find do |client|
      client[PLAYER_ID] == player_id
    end
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
      if $next_tick > t
        sleep $next_tick - t
      else
        unless @tick.zero?
          @console.wrn "tick took #{t - $next_tick} too long"
        end
      end
      $next_tick = Time.now + MAX_TICK_SPEED
      @tick += 1
      @players = @gamelogic.tick(@map, @players, diff)
      # there is no gurantee the client will tick here
      # there might be 2 gamelogic ticks and posticks
      # before the server recieves client data
      # since it is a nonblocking read and server/client are not in perfect sync
      @clients.each do |client|
        begin
          client_tick(client, diff)
        rescue Errno::ECONNRESET, Errno::ENOTCONN, EOFError, IOError
          disconnect_client(client)
        end
      end
      @players = @gamelogic.posttick(@players, diff)
    end
  end

  def ban_client(client, seconds, message = 'banned')
    port, ip = Socket.unpack_sockaddr_in(client.getpeername)
    ban_ip(ip, seconds, message)
    net_write("0l#{NET_ERR_BAN}#{message}"[0..SERVER_PACKAGE_LEN].ljust(SERVER_PACKAGE_LEN, ' '), client)
    client.close
  end

  def ban_ip(ip, seconds, message)
    @bans[ip] = Time.now + seconds
    @console.log "IP=#{ip} banned for #{seconds} seconds (#{message})"
  end

  def ip_banned?(ip)
    return false if @bans[ip].nil?

    @bans[ip] - Time.now > 0
  end

  private

  def num_ip_connected(ip)
    connected = 0
    @clients.each do |client|
      port, conencted_ip = Socket.unpack_sockaddr_in(client[NET_CLIENT].getpeername)
      connected += 1 if conencted_ip == ip
    end
    connected
  end

  def accept(server)
    last_connect = Hash.new([Time.now,0])
    Socket.accept_loop(server) do |client|
      port, ip = Socket.unpack_sockaddr_in(client.getpeername)
      if ip_banned?(ip)
        net_write("0l#{NET_ERR_BAN}banned".ljust(SERVER_PACKAGE_LEN, ' '), client)
        client.close
        next
      end
      diff = Time.now - last_connect[ip][0]
      if diff < 3
        last_connect[ip][1] += 1
        if last_connect[ip][1] > 2
          last_connect[ip][1] = 0
          ban_client(client, 10, "banned for 10 seconds (too many reconnects)")
          next
        end
      end
      @clients << [client, -1]
      @console.log "client connected IP=#{ip} (total #{@clients.count})"
      last_connect[ip][0] = Time.now
    end
  end

  def net_write(data, cli)
    # @console.dbg("sending: #{data}")
    cli.write(data)
  end
end

srv = ServerCore.new
srv.run
