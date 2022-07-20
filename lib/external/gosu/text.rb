# frozen_string_literal: true

# https://github.com/gosu/gosu-examples/blob/master/examples/text_input.rb
# Gosu is released under the MIT license.
require 'gosu'

# Input text boxes
class TextField < Gosu::TextInput
  FONT = Gosu::Font.new(60)
  WIDTH = 800
  LENGTH_LIMIT = 20
  PADDING = 5

  INACTIVE_COLOR  = 0xcc_666666
  ACTIVE_COLOR    = 0xcc_555555
  SELECTION_COLOR = 0xcc_444444
  CARET_COLOR     = 0xff_ffffff

  attr_reader :x, :y

  def initialize(window, x, y)
    # It's important to call the inherited constructor.
    super()

    @window = window
    @x = x
    @y = y

    # Start with a self-explanatory text in each field.
    self.text = 'Click to edit'
  end

  # In this example, we use the filter method to prevent the user from entering a text that exceeds
  # the length limit. However, you can also use this to blacklist certain characters, etc.
  def filter(new_text)
    allowed_length = [LENGTH_LIMIT - text.length, 0].max
    new_text[0, allowed_length]
  end

  def draw(z)
    # Change the background colour if this is the currently selected text field.
    color = if @window.text_input == self
              ACTIVE_COLOR
            else
              INACTIVE_COLOR
            end
    # ChillerDragon's epic shadow to at least have edited the stolen sample a lil bit
    Gosu.draw_rect (x - PADDING) + 5, (y - PADDING) + 5, WIDTH + (2 * PADDING), height + (2 * PADDING), INACTIVE_COLOR,
                   z
    Gosu.draw_rect x - PADDING, y - PADDING, WIDTH + (2 * PADDING), height + (2 * PADDING), color, z
    Gosu.draw_rect x - PADDING, y - PADDING, WIDTH + (2 * PADDING), height + (2 * PADDING), color, z

    # Calculate the position of the caret and the selection start.
    pos_x = x + FONT.text_width(text[0...caret_pos])
    sel_x = x + FONT.text_width(text[0...selection_start])
    sel_w = pos_x - sel_x

    # Draw the selection background, if any. (If not, sel_x and pos_x will be
    # the same value, making this a no-op call.)
    Gosu.draw_rect sel_x, y, sel_w, height, SELECTION_COLOR, z

    # Draw the caret if this is the currently selected field.
    Gosu.draw_line pos_x, y, CARET_COLOR, pos_x, y + height, CARET_COLOR, z if @window.text_input == self

    # Finally, draw the text itself!
    FONT.draw_text text, x, y, z
  end

  def height
    FONT.height
  end

  # Hit-test for selecting a text field with the mouse.
  def under_mouse?
    @window.mouse_x > x - PADDING and @window.mouse_x < x + WIDTH + PADDING and
      @window.mouse_y > y - PADDING and @window.mouse_y < y + height + PADDING
  end
end
