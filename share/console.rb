DEBUG = true

# Console used by Client and Server
class Console
  def log(message)
    t = Time.now
    puts "[#{t.hour}:#{t.min}:#{t.sec}][log] #{message}"
  end

  def dbg(message)
    return unless DEBUG

    t = Time.now
    puts "[#{t.hour}:#{t.min}:#{t.sec}][debug] #{message}"
  end
end

$console = Console.new
