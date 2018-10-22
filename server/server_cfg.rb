require 'json'

# The server side repository usign JSON
class ServerCfg
  attr_reader :data

  def initialize(console, file = 'server.json')
    @file = file
    @console = console
    @data = load
  end

  def load
    @console.log "Loading config.json"
    data = JSON.parse(File.read(@file))
    @console.log "Loaded port='#{data['port']}'"
    data
  end
end
