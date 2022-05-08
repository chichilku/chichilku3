# frozen_string_literal: true

# Renderer for moving textures like grass
class Particles
  def initialize(console)
    @console = console
    @grass_img = Gosu::Image.new(img('grass/single_64.png'))
  end

  def draw(game_map, players)
    # y = MAP_HEIGHT * TILE_SIZE - TILE_SIZE * 3
    # y += TILE_SIZE / 2
    # y += 2
    # grass(0, TILE_SIZE * 5, y, move_x, move_y)

    game_map.grass_rows.each do |grass_row|
      grass(grass_row[:x1], grass_row[:x2], grass_row[:y], players)
    end
  end

  private

  def img(path)
    File.join(File.dirname(__FILE__), '../../lib/client/img/', path)
  end

  def grass(x1, x2, y, players, density = 3)
    # @console.log(x1.to_s + " " + x2.to_s + " " + y.to_s + " " + move_x.to_s + " " + move_y.to_s)
    srand(0)
    x = x1
    amount = (x2 - x1) / density
    amount.times do
      x += density
      rot = rand(-8..8)
      move = false
      players.each do |player|
        next unless player.x > x - 10 && player.x < x + 10 && player.y > y - 128 && player.y < y + 128

        move = true
        break
      end
      if move
        if rot.positive?
          rot += 2
        else
          rot -= 2
        end
        @grass_img.draw_rot(x + rand(-3..3), y + rand(0..3) + 1, 0, rot)
      else
        @grass_img.draw_rot(x + rand(-3..3), y + rand(0..3), 0, rot)
      end
    end
  end
end
