# frozen_string_literal: true

# Renderer for moving textures like grass
class Particles
  def initialize(console)
    @console = console
    @grass_img = Gosu::Image.new(img('grass/single_64.png'))
  end

  def draw(move)
    y = MAP_HEIGHT * TILE_SIZE - TILE_SIZE * 3
    y += TILE_SIZE / 2
    y += 2
    grass(0, TILE_SIZE * 5, y, move)
  end

  private

  def img(path)
    File.join(File.dirname(__FILE__), '../../lib/client/img/', path)
  end

  def grass(x1, x2, y, move, density = 3)
    srand(0)
    x = x1
    amount = (x2 - x1) / density
    amount.times do
      x += density
      rot = rand(-8..8)
      if move > x - 10 && move < x + 10
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
