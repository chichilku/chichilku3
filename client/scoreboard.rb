
def draw_scoreboard(win_size_x, win_size_y, players, font)
    # TODO: do not compute those every frame
    padX = win_size_x / 3
    sizeX = win_size_x / 3
    padY = win_size_y / 6
    sizeY = win_size_y / 3
    slot_height = sizeY / MAX_CLIENTS
    text_scale = slot_height / 15
    # background
    draw_rect(padX, padY, sizeX, sizeY, 0xaa000000)
    # left border
    draw_rect(padX, padY, 3, sizeY, 0xaa000000)
    # right border
    draw_rect(padX + sizeX - 3, padY, 3, sizeY, 0xaa000000)
    (0..MAX_CLIENTS).each do |i|
    # row borders
    draw_rect(padX + 3, padY + (i * slot_height), sizeX - 6, 3, 0xaa000000)
    end
    players.each_with_index do | player, i |
        score_offset = text_scale * 10 * player.score.to_s.length
        font.draw_text(player.name, padX + 5, padY + (i * slot_height), 0, text_scale, text_scale)
        font.draw_text(player.score, padX + sizeX - score_offset, padY + (i * slot_height), 0, text_scale, text_scale)
    end
end
