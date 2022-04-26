# frozen_string_literal: true

def draw_scoreboard(win_size_x, win_size_y, players, font, debug)
  # TODO: do not compute those every frame
  pad_x = win_size_x / 3
  size_x = win_size_x / 3
  pad_y = win_size_y / 6
  size_y = win_size_y / 3
  slot_height = size_y / MAX_CLIENTS
  text_scale = slot_height / 15
  # background
  draw_rect(pad_x, pad_y, size_x, size_y + 3, 0xaa000000)
  # left border
  draw_rect(pad_x, pad_y, 3, size_y + 3, 0xaa000000)
  # right border
  draw_rect(pad_x + size_x - 3, pad_y, 3, size_y + 3, 0xaa000000)
  (0..MAX_CLIENTS).each do |i|
    # row borders
    draw_rect(pad_x + 3, pad_y + (i * slot_height), size_x - 6, 3, 0xaa000000)
  end
  players.each_with_index do |player, i|
    score_offset = text_scale * 10 * player.score.to_s.length
    dbg = 0
    if debug
      dbg += 25
      score_offset += 25
      font.draw_text(player.id, pad_x + 5, pad_y + (i * slot_height), 0, text_scale, text_scale, 0xFF00FF00)
    end
    font.draw_text(player.name, dbg + pad_x + 5, pad_y + (i * slot_height), 0, text_scale, text_scale)
    font.draw_text(player.score, dbg + pad_x + size_x - score_offset, pad_y + (i * slot_height), 0, text_scale,
                   text_scale)
  end
end
