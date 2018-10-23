require 'socket'

# game

TILE_SIZE = 32
WINDOW_SIZE_X = TILE_SIZE * 32
WINDOW_SIZE_Y = TILE_SIZE * 16
SPEED = TILE_SIZE

# networking

NAME_LEN = 5
MAX_CLIENTS = 3
CLIENT_PACKAGE_LEN = 7                    # used by server
SERVER_PACKAGE_LEN = MAX_CLIENTS * 8 + 4  # used by client

MAX_TIMEOUT = 5
MAX_TICK_SPEED = 0.0001 # the lower the fast client and server tick
# MAX_TICK_SPEED = 0.005

# Client packages:
# Update package
# Error package (not used yet)
# prot  pSTATUS errorcode
# 0     l       00000
#
# ID request package
# prot pSTATUS  username (prot=0 is the join protocol)
# 1     l        00000
#
# id move requests
# prot  pSTATUS id lrj (left/right/jump)
# 2     l       01 000
#
# request usernames (resets positions ->  should happen 1time at join)
# prot  pSTATUS space(for maybe an auth key or something)
# 3     l       00000
#
# cmd send
# prot  pSTATUS id  message
# 4     l       00  000

# Server packages:
# Error package (404=server full)
# prot  pSTATUS   errorcode place for more
# 0     l         404       00000000000000000000000
#
# Update package
#                               player1      player2      player3
# prot  pSTATUS     playercount id posx posy id posx posy id posx posy
# 1     l           03          01 000  000  02 000  000  03 000  000
#
# Set ID package
# prot  pSTATUS     playercount ID  Place for more info
# 2     l           03          01  0000000000000000000000
#
# Username package
#                                 player1  player2  player3
# prot  pSTATUS     playercount id name  id name  id name  empty
# 3     l           03          00 00000 00 00000 00 00000 000
#
# cmd response package ( TODO: implement it client side only prints in console for now )
# prot  pSTATUS     response
# 4     l           00000000000000000000000000
#
# Event package
# prot  pSTATUS eventcode event-details
# 5     l       x         0000000000000000000000000
#               EVENTS:
#  death:       eventcode x   y   place-for-more
#               d         000 000 0000000000000000000

# pSTATUS is a status of the current protocol
# Different status codes:
# 'l' lonley single packet
# 's' start package of a series
# 'e' end of a series
# '1','2','3',..,'9' index of current series

def save_read(socket, size)
  begin
    return socket.read_nonblock(size)
  rescue IO::WaitReadable
    return ''
  end
end
