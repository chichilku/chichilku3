# frozen_string_literal: true

require 'socket'
# check doc_network.rb for documentation

# update GAME_VERSION on network protocol changes
GAME_VERSION = '0015'

# game

TILE_SIZE = 64
MAP_WIDTH = 16
MAP_HEIGHT = 9
WINDOW_SIZE_X = TILE_SIZE * MAP_WIDTH
WINDOW_SIZE_Y = TILE_SIZE * MAP_HEIGHT
FULLHD_X = 1920
UI_SCALE = WINDOW_SIZE_X.to_f / FULLHD_X
SPEED = TILE_SIZE

# networking

CMD_LEN = 7
NAME_LEN = 9
MAX_MAPNAME_LEN = 43
MAX_CLIENTS = 12
PLAYER_PACKAGE_LEN = 16
CLIENT_PACKAGE_LEN = 11 # used by server
SERVER_PACKAGE_LEN = MAX_CLIENTS * PLAYER_PACKAGE_LEN + 4 # used by client

MAX_TIMEOUT = 5
MAX_TICK_SPEED = 0.01 # the lower the faster client and server tick
# MAX_TICK_SPEED = 0.005

NET_ERR_FULL = '404'
NET_ERR_DISCONNECT = '001'
NET_ERR_KICK = '002'
NET_ERR_BAN = '003'
NET_ERR_SERVER_OUTDATED = '004'
NET_ERR_CLIENT_OUTDATED = '005'

NET_ERR = {
  '404' => 'SERVER FULL',
  '001' => 'DISCONNECTED',
  '002' => 'KICKED',
  '003' => 'BANNED',
  '004' => 'SERVER OUTDATED',
  '005' => 'CLIENT OUTDATED'
}.freeze

CLIENT_PCK_TYPE = {
  error: '0',
  join: '1',
  move: '2',
  info: '3',
  cmd: '4'
}.freeze

SERVER_PCK_TYPE = {
  error: '0',
  update: '1',
  # TODO: find a good name here
  info: '3',
  cmd: '4',
  event: '5'
}.freeze

NET_INT_OFFSET = 33
NET_INT_BASE = 93
NET_MAX_INT = NET_INT_BASE
NET_MIN_INT = 0

##
# Converts a integer to single character network string
#
# the base of the network is NET_INT_BASE
# so the number 93 is the last single character number represented as '~'
#
# @param [Integer, #chr] int decimal based number
# @return [String] the int converted to base NET_INT_BASE

def net_pack_int(int)
  net_error "#{__method__}: '#{int}' is too low allowed range #{NET_MIN_INT}-#{NET_MAX_INT}" if int < NET_MIN_INT
  net_error "#{__method__}: '#{int}' is too high allowed range #{NET_MIN_INT}-#{NET_MAX_INT}" if int > NET_MAX_INT
  int += NET_INT_OFFSET
  int.chr
end

##
# Converts a single character network string to integer
#
# the base of the network is NET_INT_BASE
# so the number 93 is the last single character number represented as '~'
#
# @param [String, #ord] net_int network packed string
# @return [Integer] the net_int converted to decimal based number

def net_unpack_int(net_int)
  net_int.ord - NET_INT_OFFSET
end

##
# Converts a integer to multi character network string
#
# @param [Integer, #net_pack_int] int decimal based number
# @param [Integer] size max length of the network string
# @return [String] the int converted to base NET_INT_BASE

def net_pack_bigint(int, size)
  sum = ''
  div = size - 1
  (size - 1).times do
    buf = int / ((NET_MAX_INT + 1)**div)
    sum += net_pack_int(buf)
    int = int % ((NET_MAX_INT + 1)**div)
    div -= 1
  end
  sum += net_pack_int(int)
  # TODO: check reminder and so on
  # throw and error when int is too big for size
  int /= NET_MAX_INT
  sum
end

##
# Converts a multi character network string to integer
#
# @param [String, #net_unpack_int] net_int network packed int
# @return [Integer] the net_int converted to decimal based number

def net_unpack_bigint(net_int)
  sum = 0
  net_int.chars.reverse.each_with_index do |c, i|
    if i.zero?
      sum = net_unpack_int(c)
    else
      sum += net_unpack_int(c) * (NET_MAX_INT + 1)**i
    end
  end
  sum
end

def save_read(socket, size)
  socket.read_nonblock(size)
rescue IO::WaitReadable
  ''
end

def net_error(err)
  raise "NetError: #{err}"
end
