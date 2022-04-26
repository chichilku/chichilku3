# frozen_string_literal: true

require_relative 'console'

# Projectile class handles arrow logic
class Projectile
  attr_accessor :x, :y, :dx, :dy, :r, :w, :h, :owner_id

  def initialize
    @x = 0
    @y = 0
    @dx = 0
    @dy = 0
    @w = 16
    @h = 16
    @owner = nil
    @left_owner = false
    @flying = false
    @tick = 0
  end

  def fire(x, y, dx, dy, owner)
    return if @flying

    @x = x
    @y = y
    @dx = dx
    @dy = dy
    calc_rotation
    @owner = owner
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
    @x += @dx
    @y += @dy
    @dy += 1 if (@tick % 3).zero?
    calc_rotation
    check_hit(players)
    hit if  @y > WINDOW_SIZE_Y
    hit if  @x > WINDOW_SIZE_X
    hit if @x.negative?
  end

  def check_hit(players)
    owner_hit = false
    players.each do |player|
      next unless player.x + player.w > @x && player.x < @x + @w

      if player.y + player.h > @y && player.y < @y + @h
        if @owner.id == player.id
          owner_hit = true
          if @left_owner
            player.damage(@owner)
            hit
          end
        else
          player.damage(@owner)
          hit
        end
      end
    end
    @left_owner = true if owner_hit == false
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
    @r = xy_to_rotation(@x, @y)
  end

  private

  def xy_to_rotation(delta_x, delta_y)
    if delta_y > -3 && delta_y < 3
      if x.negative?
        4
      else
        0
      end
    elsif delta_y.negative?
      if delta_x > -3 && delta_x < 3
        6
      elsif delta_x.negative?
        5
      else
        7
      end
    elsif delta_x > -3 && delta_x < 3
      2
    elsif delta_x.negative?
      3
    end
    1
  end
end
