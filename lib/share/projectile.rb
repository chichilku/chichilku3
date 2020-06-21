require_relative 'console'

class Projectile
    attr_accessor :x, :y, :dx, :dy, :r, :w, :h, :owner_id

    def initialize
        @x = 0
        @y = 0
        @dx = 0
        @dy = 0
        @w = 16
        @h = 16
        @owner_id = nil
        @left_owner = false
        @flying = false
        @tick = 0
    end

    def fire(x, y, dx, dy, owner_id)
        return if @flying

        @x = x
        @y = y
        @dx = dx
        @dy = dy
        calc_rotation()
        @owner_id = owner_id
        @left_owner = false
        @flying = true
        $console.dbg "Projectile(x=#{x}, y=#{y}, dx=#{dx}, dy=#{dy})"
    end

    def hit
        @flying = false
        @x = 0
        @y = 0
    end

    def tick(players)
        return unless @flying

        @tick += 1
        @x = @x + @dx
        @y = @y + @dy
        @dy += 1 if @tick % 3 == 0
        calc_rotation()
        check_hit(players)
        hit if  @y > WINDOW_SIZE_Y
        hit if  @x > WINDOW_SIZE_X
        hit if @x < 0 || @y < 0
    end

    def check_hit(players)
        owner_hit = false
        players.each do |player|
            if player.x + player.w > @x && player.x < @x + @w
                if player.y + player.h > @y && player.y < @y + @h
                    if owner_id == player.id
                        owner_hit = true
                        player.damage if @left_owner
                    else
                        player.damage
                    end
                end
            end
        end
        if owner_hit == false
            @left_owner = true
        end
    end

    # NETWORK ROTATION
    # 0 ->     4 <-

    #           ^
    # 1 \      5 \
    #    v

    #            ^
    # 2 |      6 |
    #   v

    #             ^
    # 3 /      7 /
    #  v
    def calc_rotation
        if @dy > -3 && @dy < 3
            if @dx < 0
                @r = 4
            else
                @r = 0
            end
        elsif @dy < 0
            if @dx > -3 && @dx < 3
                @r = 6
            elsif @dx < 0
                @r = 5
            else
                @r = 7
            end
        else
            if @dx > -3 && @dx < 3
                @r = 2
            elsif @dx < 0
                @r = 3
            else
                @r = 1
            end
        end
    end
end
