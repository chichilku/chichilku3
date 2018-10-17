require 'socket'

NAME_LEN = 5
MAX_CLIENTS = 3
CLIENT_PACKAGE_LEN = 6                    # used by server
SERVER_PACKAGE_LEN = MAX_CLIENTS * 8 + 3  # used by client

# Client packages:
# Update package
# Error package (not used yet)
# prot  errorcode
# 0     00000
#
# ID request package
# prot username (prot=0 is the join protocol)
# 1     00000
#
# id move requests
# prot  id lrx (left/right/x=place for more)
# 2     01 000
#
# request usernames (resets positions ->  should happen 1time at join)
# prot  space(for maybe an auth key or something)
# 3     00000

# Server packages:
# Error package (404=server full)
# prot  errorcode place for more
# 0     404       00000000000000000000000
#
# Update package
#                   player1      player2      player3
# prot  playercount id posx posy id posx posy id posx posy
# 1     03          01 000  000  02 000  000  03 000  000
#
# Set ID package
# prot  playercount ID  Place for more info
# 2     03          01  0000000000000000000000
#
# Username package
#                   player1  player2  player3
# prot  playercount id name  id name  id name  empty
# 3     03          00 00000 00 00000 00 00000 000

def save_read(socket, size)
  begin
    return socket.read_nonblock(size)
  rescue IO::WaitReadable
    return ''
  end
end
