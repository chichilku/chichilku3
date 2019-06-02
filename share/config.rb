require 'json'

# chichilku3 config base used by client and server
class Config
  attr_reader :data

  def initialize(console, file)
    @file = file
    @console = console
    @data = load
  end

  def sanitize_data(data)
    data
  end

  def load
    data = JSON.parse(File.read(@file))
    data = sanitize_data(data)
    data
  end
end
