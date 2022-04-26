# frozen_string_literal: true

require_relative 'string'
DEBUG = false

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
    puts format('[%02d:%02d:%02d][%s] %s', t.hour, t.min, t.sec, type, message)
  end
end

$console = Console.new
