require 'json'
require_relative '../share/network'

# The client side repository usign JSON
class ClientCfg
  attr_reader :data

  def initialize(console, file = 'client.json')
    @file = file
    @console = console
    @data = load
  end

  def load
    data = JSON.parse(File.read(@file))
    if data['username'].length > NAME_LEN
      data['username'] = data['username'][0..NAME_LEN - 1]
      @console.log "username to long chopped to '#{data['username']}'"
    end
    data
  end
end
