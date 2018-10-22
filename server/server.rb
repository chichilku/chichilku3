require 'socket'

require_relative '../share/console'
require_relative '../share/network'
require_relative '../share/player'

require_relative 'gamelogic'

$time_point=Time.now
$time_buffer=0

def get_frame_time
  diff = Time.now - $time_point
  $time_point = Time.now
  return diff
end

# ServerCore: should only cotain the networking
# and no gamelogic
class ServerCore
  def initialize
    @players = []
    @clients = []
    @current_id = 0
    @tick = 0
    @console = Console.new
    @gamelogic = GameLogic.new(@console)
  end

  def create_name_package
    # protocol 3 name prot
    pck = format('3l%02d', @players.count)
    @players.each do |player|
      pck += player.to_n_pck
      @console.dbg "pname=#{player.name}"
    end
    pck.ljust(SERVER_PACKAGE_LEN, '0')
  end

  def add_player(name)
    @current_id += 1
    return -1 if @current_id > MAX_CLIENTS

    @console.log "Added player #{@current_id}"
    @players << Player.new(@current_id, nil, nil, name)
    @current_id # implicit return
  end

  def players_to_packet
    packet = @players.empty? ? '00' : format('%02d', @players.count)
    @players.each do |player|
      packet += player.to_s
    end
    # fill with zeros if less than 3 players online
    packet.ljust(SERVER_PACKAGE_LEN - 2, '0') # implicit return
  end

  def update_pck(data, dt)
    id = data[0..1].to_i
    @console.dbg "got player with id: #{id}"
    @players = @gamelogic.handle_client_requests(data[2..-1], id, @players, dt)
    nil # defaults to normal update pck
  end

  def id_pck(data)
    name = data[0..5]
    id = add_player(name)
    if id == -1
      puts "'#{name}' failed to connect (server full)"
      # protocol 0 (error) code=404 slot not found
      return '0l40400000000000000000000000'
    end
    @console.log "'#{name}' joined the game"
    # protocol 2 (id)
    format('2l00%02d0000000000000000000000', id).to_s
  end

  def command_package(data)
    @console.log "command: #{data}"
    msg = "hello world"
    msg = msg.ljust(SERVER_PACKAGE_LEN - 2, '0')
    msg = msg[0..SERVER_PACKAGE_LEN - 2]
    "4l#{msg}"
  end

  def handle_protocol(protocol, p_status, data, dt)
    @console.dbg "HANDLE PROTOCOL=#{protocol} status=#{p_status}"
    if protocol.zero? # error pck
      @console.log "Error pck=#{data}"
    elsif protocol == 1 # id pck
      return id_pck(data)
    elsif protocol == 2 # update pck
      return update_pck(data, dt)
    elsif protocol == 3 # initial request names
      return create_name_package
    elsif protocol == 4 # command
      return command_package(data)
    else
      @console.log "ERROR unkown protocol=#{protocol} data=#{data}"
    end
  end

  def handle_client_data(data, dt)
    response = handle_protocol(data[0].to_i, data[1], data[2..-1], dt)
    return response unless response.nil?

    if (@tick % 100).zero?
      # return '3l0301hello02x0x0x03hax0r000'
      return create_name_package
    end

    # if error occurs or something unexpected
    # just send regular update pck
    # protocol 1 (update)
    "1l#{players_to_packet}" # implicit return
  end

  # TODO: this func and it dependencies should be new file
  # Handles each client
  def client_tick(cli, dt)
    client_data = save_read(cli, CLIENT_PACKAGE_LEN)
    return if client_data == ''

    @console.dbg "recv: #{client_data}"
    server_response = handle_client_data(client_data, dt)
    # server_response = '1l03011001010220020203300303'
    net_write(server_response, cli)
  end

  def run
    server = TCPServer.open(2000)
    loop do
      accept(server)
      # accept_and_tick(server) # experimental
    end
  end

  private

  def tick(client)
    # TODO: implement me as a global tick iterating over all clients
    # get the client connections from the accept() method
    # and then store them into an array
    # then iterate over the array in this tick function
    # this allows communication bewteen the clients
    # because they are no longer in speperate threads
  end

  # def accept_and_tick(server)
  #   Thread.start(server.accept) do |client|
  #     client_id = 1 # TODO: get client id as package
  #     @clients.each do |other_client|
  #       if client_id == other_client.id || client == other_client
  #         net_write('0l404_id_taken____0000000000', client)
  #         Thread.kill self
  #       end
  #     end
  #     @console.log "#{client} joined the game"
  #     @clients = client
  #     # client joined the game (set hardcodet id to 1)
  #     net_write('2l00010000000000000000000000', client)

  #     tick(client)
  #   end
  # end

  def accept(server)
    Thread.start(server.accept) do |client|
      diff = 0
      loop do
        $time_buffer += get_frame_time
        start = Time.now
        if ($time_buffer > MAX_TICK_SPEED)
          @tick += 1
          # sleep(1)
          # client.write("123")
          # @console.dbg "im here client: #{client}"
          client_tick(client, diff)
          $time_buffer = 0
        end
        stop = Time.now
        diff = stop - start
        # @console.log "TirmelDetat: #{diff}"
      end
      client.close
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
