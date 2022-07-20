# frozen_string_literal: true

require 'json'
require 'os'
require 'fileutils'

# chichilku3 config base used by client and server
class Config
  attr_reader :data, :chichilku3_dir

  def initialize(console, file)
    @chichilku3_dir = ''
    if OS.linux?
      @chichilku3_dir = "#{Dir.home}/.chichilku/chichilku3/"
    elsif OS.mac?
      @chichilku3_dir = "#{Dir.home}/Library/Application Support/chichilku/chichilku3/"
    # elsif OS.windows?
    #   @chichilku3_dir = "%APPDATA%\\chichilku\\chichilku3\\"
    else
      puts 'os not supported.'
      exit
    end
    puts "path: #{@chichilku3_dir}"
    FileUtils.mkdir_p @chichilku3_dir
    FileUtils.mkdir_p "#{@chichilku3_dir}recordings"
    FileUtils.mkdir_p "#{@chichilku3_dir}maps_b64"
    FileUtils.mkdir_p "#{@chichilku3_dir}downloadedmaps"
    FileUtils.mkdir_p "#{@chichilku3_dir}tmp"
    unless File.directory? "#{@chichilku3_dir}maps"
      if File.directory? 'maps'
        FileUtils.cp_r 'maps', "#{@chichilku3_dir}maps"
      else
        FileUtils.mkdir_p "#{@chichilku3_dir}maps"
      end
    end
    @source_file = File.join(File.dirname(__FILE__), '../../', file)
    create_default_cfg(@source_file, "#{@chichilku3_dir}/#{file}")
    @file = @chichilku3_dir + file
    @console = console
    @data = load
  end

  def create_default_cfg(from, to)
    return if File.file?(to)

    tmp = JSON.parse(File.read(from))
    File.write(to, tmp.to_json)
  end

  def sanitize_data(data)
    data
  end

  def load
    defaults = JSON.parse(File.read(@source_file))
    data = JSON.parse(File.read(@file))
    data = defaults.merge(data)
    sanitize_data(data)
  end

  def save
    File.write(@file, JSON.pretty_generate(data))
  end
end
