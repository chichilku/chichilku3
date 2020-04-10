require 'socket'
# check doc_network.rb for documentation

# update GAME_VERSION on network protocol changes
GAME_VERSION = '0002'

# game

TILE_SIZE = 64
WINDOW_SIZE_X = TILE_SIZE * 16
WINDOW_SIZE_Y = TILE_SIZE * 8
SPEED = TILE_SIZE

# networking

NAME_LEN = 5
MAX_CLIENTS = 3
CLIENT_PACKAGE_LEN = 7                    # used by server
SERVER_PACKAGE_LEN = MAX_CLIENTS * 8 + 4  # used by client

MAX_TIMEOUT = 5
MAX_TICK_SPEED = 0.01 # the lower the faster client and server tick
# MAX_TICK_SPEED = 0.005

NET_MAX_SCORE = 255
NET_MIN_SCORE = 0

NET_ERR_FULL = "404"

NET_ERR = {
  "404" => "SERVER FULL"
}

def save_read(socket, size)
  begin
    return socket.read_nonblock(size)
  rescue IO::WaitReadable
    return ''
  end
end

def net_error(err)
  puts "Error: #{err}"
  exit 1
end

def net_pack_int(int)
  net_error "#{__method__}: '#{int}' is too low allowed range #{NET_MIN_SCORE}-#{NET_MAX_SCORE}" if int < NET_MIN_SCORE
  net_error "#{__method__}: '#{int}' is too high allowed range #{NET_MIN_SCORE}-#{NET_MAX_SCORE}" if int > NET_MAX_SCORE
  int.chr
end

def net_unpack_int(pack_int)
  pack_int.ord
end
