require_relative 'console'

class Projectile
    attr_accessor :x, :y, :dx, :dy

    def initialize
        @x = 0
        @y = 0
        @dx = 0
        @dy = 0
        @flying = false
    end

    def fire(x, y, dx, dy)
        return if @flying

        @x = x
        @y = y
        @dx = dx
        @dy = dy
        @flying = true
        $console.log "Projectile(x=#{x}, y=#{y}, dx=#{dx}, dy=#{dy})"
    end

    def hit
        @flying = false
        @x = 0
        @y = 0
    end

    def tick
        @x = @x + @dx
        @y = @x + @dy
        @dy += 1
        hit if  @y > WINDOW_SIZE_Y
    end
end
