require_relative '../share/player'

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
    players << Player.new(id, x, y) unless id.zero?
  end
  players
end

def server_package_to_player_array(data)
  # /(?<count>\d{2})(?<player>(?<id>\d{2})(?<x>\d{3})(?<y>\d{3}))/
  slots = data[0..1].to_i # save slots
  data = data[2..-1] # cut slots off
  players = server_package_to_player_strs(slots, data)
  # puts players
  player_strs_to_objects(players)
end

# 3 players
pl3 = '03011001010220020203300303'
p server_package_to_player_array(pl3)
p server_package_to_player_array(pl3).count
# 2 players (first has id 00 -> offline)
pl2 = '03001001010220020203300303'
p server_package_to_player_array(pl2)
p server_package_to_player_array(pl2).count
