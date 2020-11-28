require 'json'
require 'os'
require 'fileutils'

# chichilku3 config base used by client and server
class Config
  attr_reader :data, :chichilku3_dir

  def initialize(console, file)
    @chichilku3_dir = ""
    if OS.linux?
      @chichilku3_dir = "#{ENV['HOME']}/.chichilku/chichilku3/"
    elsif OS.mac?
      @chichilku3_dir = "#{ENV['HOME']}/Library/Application Support/chichilku/chichilku3/"
    # elsif OS.windows?
    #   @chichilku3_dir = "%APPDATA%\\chichilku\\chichilku3\\"
    else
      puts "os not supported."
      exit
    end
    puts "path: " + @chichilku3_dir
    FileUtils.mkdir_p @chichilku3_dir
    FileUtils.mkdir_p "#{@chichilku3_dir}recordings"
    FileUtils.mkdir_p "#{@chichilku3_dir}maps_b64"
    FileUtils.mkdir_p "#{@chichilku3_dir}downloadedmaps"
    FileUtils.mkdir_p "#{@chichilku3_dir}tmp"
    unless File.directory? "#{@chichilku3_dir}maps"
      if File.directory? "maps"
        FileUtils.cp_r "maps", "#{@chichilku3_dir}maps"
      else
        FileUtils.mkdir_p "#{@chichilku3_dir}maps"
      end
    end
    create_default_cfg(file, "#{@chichilku3_dir}/#{file}")
    @source_file = file
    @file = @chichilku3_dir + file
    @console = console
    @data = load
  end

  def create_default_cfg(from, to)
    return if File.file?(to)

    tmp = JSON.parse(File.read(from))
    File.open(to,"w") do |f|
      f.write(tmp.to_json)
    end
  end

  def sanitize_data(data)
    data
  end

  def load
    defaults = JSON.parse(File.read(@source_file))
    data = JSON.parse(File.read(@file))
    data = defaults.merge(data)
    data = sanitize_data(data)
    data
  end

  def save
    File.open(@file, "w") do |f|
      f.write(JSON.pretty_generate(data))
    end
  end
end
