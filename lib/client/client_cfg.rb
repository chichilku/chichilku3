require 'json'
require_relative '../share/network'
require_relative '../share/config'

# The client side repository using JSON
class ClientCfg < Config
  def sanitize_data(data)
    data = JSON.parse(File.read(@file))
    if data['username'].length > NAME_LEN
      data['username'] = data['username'][0..NAME_LEN - 1]
      @console.log "username to long chopped to '#{data['username']}'"
    end
    data
  end
end
