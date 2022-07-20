# frozen_string_literal: true

require_relative 'string'
DEBUG = false
DEBUG_PHYSICS = true

# Console used by Client and Server
class Console
  def log(message)
    log_type('log', message)
  end

  def err(message)
    log_type('error'.red, message)
  end

  def wrn(message)
    log_type('warning'.yellow, message)
  end

  def dbg(message)
    return unless DEBUG

    log_type('debug'.pink, message)
  end

  private

  def log_type(type, message)
    t = Time.now
    puts format('[%<hour>02d:%<min>02d:%<sec>02d][%<type>s] %<msg>s',
                hour: t.hour,
                min: t.min,
                sec: t.sec,
                type:,
                msg: message)
  end
end

$console = Console.new
