require 'socket'
# check doc_network.rb for documentation

# update GAME_VERSION on network protocol changes
GAME_VERSION = '0001'

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

def save_read(socket, size)
  begin
    return socket.read_nonblock(size)
  rescue IO::WaitReadable
    return ''
  end
end
