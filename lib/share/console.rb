DEBUG = false

# Console used by Client and Server
class Console
  def log(message)
    t = Time.now
    puts format("[%02d:%02d:%02d][log] #{message}", t.hour, t.min, t.sec, message)
  end

  def dbg(message)
    return unless DEBUG

    t = Time.now
    puts format("[%02d:%02d:%02d][debug] #{message}", t.hour, t.min, t.sec, message)
  end
end

$console = Console.new
