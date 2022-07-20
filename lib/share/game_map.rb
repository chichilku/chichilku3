# frozen_string_literal: true

require 'base64'
require 'digest/sha1'
require 'zip'
require 'fileutils'

require_relative '../external/rubyzip/recursive'

MAX_UNZIP_SIZE = 1024**2 # 1MiB
MAP_VERSION = 1
MAP_FILES = [
  'background.png',
  'gametiles.txt',
  'metadata.json'
].freeze

# GameMap class handles the game_map file format
class GameMap
  attr_reader :gametiles, :grass_rows, :ready, :metadata

  def initialize(console, cfg, mapname, callback = nil, checksum = nil)
    @console = console
    @cfg = cfg
    @mapname = mapname
    @b64_size = -1
    @b64_data = ''
    @sha1sum = checksum
    @gametiles = []
    # grass_rows
    #   array of hashes containing connected grass tiles
    #   a row of grass from x 0 to x 10 at the height 2 would look like this
    #   {x1: 0, x2: 10, y: 2}
    @grass_rows = []
    @ready = false
    @metadata = nil

    # client
    @callback = callback
    @progress = 0
    @tmpfile = nil
  end

  def checksum
    @sha1sum
  end

  def name
    @mapname
  end

  # TODO: fix this rubocop
  # rubocop:disable Naming/AccessorMethodName
  def set_name(name)
    raise unless @mapname.nil?

    @mapname = name
  end

  def size
    @b64_size
  end

  def set_size(size)
    raise unless @b64_size == -1

    @b64_size = size
  end
  # rubocop:enable Naming/AccessorMethodName

  def load_gametiles(map_dir)
    gamefile = "#{map_dir}/gametiles.txt"
    unless File.exist? gamefile
      @console.err "could not load gametiles '#{gamefile}'"
      exit 1
    end

    is_skip = true
    @gametiles = []
    @grass_rows = []
    File.readlines(gamefile).each_with_index do |data, i|
      gamerow = data[0..-2] # cut off newline
      is_skip = !is_skip if gamerow =~ /\+-+\+/
      gamerow = gamerow.match(/\|(.*)\|/)
      next if gamerow.nil?

      gamerow = gamerow[1]
      next if is_skip

      if gamerow.length != MAP_WIDTH
        @console.err "invalid gametiles row=#{i} size=#{gamerow.length}/#{MAP_WIDTH}"
        exit 1
      end
      @gametiles << gamerow
    end
    if @gametiles.length != MAP_HEIGHT
      @console.err "invalid gametiles rows=#{@gametiles.length}/#{MAP_HEIGHT}"
      exit 1
    end
    y = 0
    grass = {}
    @gametiles.each do |gamerow|
      x = 0
      gamerow.chars.each do |tile|
        if tile == 'i'
          grass[:x2] = (x * TILE_SIZE) + TILE_SIZE
          grass[:y] = (y * TILE_SIZE) + (TILE_SIZE / 2) + 2
          grass[:x1] = x * TILE_SIZE if grass[:x1].nil?
        else
          @grass_rows.push(grass) unless grass == {}
          grass = {}
        end
        x += 1
      end
      y += 1
    end
    nil
  end

  def load_metadata(map_dir)
    metafile = "#{map_dir}/metadata.json"
    unless File.exist? metafile
      @console.err "could not load gametiles '#{metafile}'"
      exit 1
    end

    @metadata = JSON.parse(File.read(metafile))
    if @metadata['chichilku3-map-version'] != MAP_VERSION
      @console.err "Failed to load map '#{@metadata['name']}':"
      @console.err "  Expected map version '#{MAP_VERSION}' but got '#{@metadata['chichilku3-map-version']}'"
      exit 1
    end
    @console.log "loaded map '#{@metadata['name']}' (#{@metadata['version']}) by #{@metadata['authors'].join(',')}"
  end

  def load_data(map_dir)
    load_gametiles(map_dir)
    load_metadata(map_dir)
    @ready = true
  end

  def death?(x, y)
    { x:, y: } if @gametiles[y][x] == 'X'
  end

  def collision?(x, y)
    { x:, y: } if @gametiles[y][x] == 'O'
  end

  def grass?(x, y)
    { x:, y: } if @gametiles[y][x] == 'i'
  end

  # SERVER

  def prepare_upload
    return if @mapname == '' || @mapname.nil?

    map_dir = "#{@cfg.chichilku3_dir}maps/#{@mapname}"
    unless File.directory? map_dir
      @console.err "failed to load map '#{@mapname}' (directory not found)"
      exit 1
    end
    unless File.exist? "#{map_dir}/background.png"
      @console.err "failed to load map '#{@mapname}' (no background.png)"
      exit 1
    end
    unless File.exist? "#{map_dir}/gametiles.txt"
      @console.err "failed to load map '#{@mapname}' (no gametiles.txt)"
      exit 1
    end
    load_data(map_dir)
    zip
    encode
  end

  def zip
    map_dir = "#{@cfg.chichilku3_dir}maps/#{@mapname}"
    map_zip = "#{@cfg.chichilku3_dir}maps/#{@mapname}.zip"
    FileUtils.rm_rf map_zip

    @console.log "archiving map '#{map_zip}' ..."
    Zip::File.open(map_zip, Zip::File::CREATE) do |zipfile|
      MAP_FILES.each do |filename|
        filepath = File.join(map_dir, filename)
        unless File.exist? filepath
          @console.err "failed to zip map '#{@mapname}' missing file:"
          @console.err filepath
          exit 1
        end
        zipfile.add(filename, filepath)
      end
    end
  end

  def encode
    rawfile = "#{@cfg.chichilku3_dir}maps/#{@mapname}.zip"
    @console.log "encoding map archive '#{@mapname}' ..."
    File.open(rawfile, 'rb') do |map_png|
      raw_content = map_png.read
      @sha1sum = Digest::SHA1.hexdigest raw_content
      encodefile = "#{@cfg.chichilku3_dir}maps_b64/#{@mapname}_#{checksum}.zip"
      File.open(encodefile, 'wb') do |map_encoded|
        @b64_data = Base64.encode64(raw_content).delete! "\n"
        @b64_size = @b64_data.size
        map_encoded.write(@b64_data)
      end
    end
    @console.log "finished encoding size=#{@b64_size} checksum=#{checksum}"
  end

  def get_data(offset, size)
    return nil if @mapname == '' || @mapname.nil?

    if offset + size > @b64_size
      @b64_data[offset..].ljust(size, ' ')
    else
      @b64_data[offset...offset + size]
    end
  end

  # CLIENT

  def dl_path
    "#{@cfg.chichilku3_dir}downloadedmaps/#{@mapname}_#{checksum}"
  end

  def prepare_download
    @tmpfile = "#{@cfg.chichilku3_dir}tmp/#{@mapname}"
    FileUtils.rm_rf @tmpfile
  end

  def download(data)
    data.strip!
    @progress += data.size
    @console.dbg "downloading #{@progress} / #{@b64_size} ..."
    File.write(@tmpfile, data, mode: 'a')
    if @progress >= @b64_size
      @console.log 'finished download'
      @callback.call(load)
    end
    @progress
  end

  def found?
    File.directory? dl_path
  end

  def unzip
    map_archive = "#{dl_path}.zip"
    map_dir = dl_path
    FileUtils.mkdir_p map_dir
    Dir.chdir map_dir do
      Zip::File.open(map_archive) do |zip_file|
        zip_file.each do |entry|
          @console.log "extracting '#{entry.name}' ...'"
          raise 'File too large when extracted' if entry.size > MAX_UNZIP_SIZE

          entry.extract
        end
      end
    end
    FileUtils.rm_rf map_archive
    map_dir
  end

  def load
    outfile = "#{dl_path}.zip"
    @console.log 'converting downloaded map ...'
    File.open(@tmpfile, 'rb') do |map_encoded|
      File.binwrite(outfile, Base64.decode64(map_encoded.read))
    end
    unzip
  end
end
