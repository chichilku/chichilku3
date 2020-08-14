require 'base64'
require 'digest/sha1'
require 'zip'
require 'fileutils'

require_relative '../external/rubyzip/recursive'

MAX_UNZIP_SIZE = 1024**2 # 1MiB

class Map
  attr_reader :gametiles

  def initialize(console, cfg, mapname, callback = nil, checksum = nil)
    @console = console
    @cfg = cfg
    @mapname = mapname
    @b64_size = -1
    @b64_data = ""
    @sha1sum = checksum
    @gametiles = []

    # client
    @callback = callback
    @progress = 0
    @tmpfile = nil
  end

  def checksum()
    @sha1sum
  end

  def name()
    @mapname
  end

  def set_name(name)
    raise unless @mapname.nil?

    @mapname = name
  end

  def size()
    @b64_size
  end

  def set_size(size)
    raise unless @b64_size == -1

    @b64_size = size
  end

  def load_gametiles(map_dir)
    gamefile = "#{map_dir}/gametiles.txt"
    unless File.exists? gamefile
      @console.err "could not load gametiles '#{gamefile}'"
      exit 1
    end

    @gametiles = []
    File.readlines(gamefile).each_with_index do |data, i|
      gamerow = data[0..-2] # cut off newline
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
  end

  # SERVER

  def prepare_upload()
    return if @mapname == "" || @mapname.nil?

    map_dir = "#{@cfg.chichilku3_dir}maps/#{@mapname}"
    unless File.directory? map_dir
      @console.err "failed to load map '#{@mapname}' (directory not found)"
      exit 1
    end
    unless File.exists? "#{map_dir}/background.png"
      @console.err "failed to load map '#{@mapname}' (no background.png)"
      exit 1
    end
    unless File.exists? "#{map_dir}/gametiles.txt"
      @console.err "failed to load map '#{@mapname}' (no gametiles.txt)"
      exit 1
    end
    load_gametiles(map_dir)
    zip()
    encode()
  end

  def zip()
    map_dir = "#{@cfg.chichilku3_dir}maps/#{@mapname}"
    map_zip = "#{@cfg.chichilku3_dir}maps/#{@mapname}.zip"
    File.delete map_zip if File.exists? map_zip

    @console.log "archiving map '#{map_zip}' ..."
    zf = ZipFileGenerator.new(map_dir, map_zip)
    zf.write()
  end

  def encode()
    rawfile = "#{@cfg.chichilku3_dir}maps/#{@mapname}.zip"
    @console.log "encoding map archive '#{@mapname}' ..."
    File.open(rawfile, 'rb') do |map_png|
      raw_content = map_png.read
      @sha1sum = Digest::SHA1.hexdigest raw_content
      encodefile = "#{@cfg.chichilku3_dir}maps_b64/#{@mapname}_#{checksum()}.zip"
      File.open(encodefile, 'wb') do |map_encoded|
        @b64_data = Base64.encode64(raw_content).delete! "\n"
        @b64_size = @b64_data.size()
        map_encoded.write(@b64_data)
      end
    end
    @console.log "finished encoding size=#{@b64_size} checksum=#{checksum()}"
  end

  def get_data(offset, size)
    return nil if @mapname == "" || @mapname.nil?

    if offset + size > @b64_size
      @b64_data[offset ..].ljust(size, ' ')
    else
      @b64_data[offset ... offset + size]
    end
  end

  # CLIENT

  def dl_path()
    "#{@cfg.chichilku3_dir}downloadedmaps/#{@mapname}_#{checksum()}"
  end

  def prepare_download()
    @tmpfile = "#{@cfg.chichilku3_dir}tmp/#{@mapname}"
    File.delete @tmpfile if File.exists? @tmpfile
  end

  def download(data)
    data.strip!
    @progress += data.size
    @console.dbg "downloading #{@progress} / #{@b64_size} ..."
    IO.write(@tmpfile, data, mode: 'a')
    if @progress >= @b64_size
      @console.log "finished download"
      @callback.call(load)
    end
    @progress
  end

  def has_map?()
    File.directory? dl_path()
  end

  def unzip()
    map_archive = "#{dl_path()}.zip"
    map_dir = dl_path()
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
    File.delete map_archive if File.exists? map_archive
    map_dir
  end

  def load()
    outfile = "#{dl_path()}.zip"
    @console.log "converting downloaded map ..."
    File.open(@tmpfile, 'rb') do |map_encoded|
      File.open(outfile, 'wb') do |map_png|
        map_png.write(
          Base64.decode64(map_encoded.read)
        )
      end
    end
    unzip()
  end
end
