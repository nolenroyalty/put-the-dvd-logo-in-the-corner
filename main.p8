-- THE GAME: shoot the DVD logo into the corner

function _init()
    logo = { x = 64, y = 26, width = 32, height = 32, thickness = 1, dx = 1, dy = 1}
    tv = { x = 10, y = 10, width = 108, height = 108, thickness = 3 }

    frames_since_last_move = 0
    frames_between_each_move = 1
    pixels_for_each_move = 1

    corner_distance_threshold = 4
    frames_between_each_score = 15
    frames_remaining_until_we_can_score = 0
    score = 0
end

function tv_inner_left()
    return tv.x + tv.thickness - 1
end

function tv_inner_right()
    return tv.x + tv.width - tv.thickness + 1
end

function tv_inner_top()
    return tv.y + tv.thickness - 1
end

function tv_inner_bottom()
    return tv.y + tv.height - tv.thickness + 1
end

function maybe_bounce_logo()
    bounce_state = { x = 0, y = 0, hit_corner = false }
    inner_left = tv_inner_left()
    inner_right = tv_inner_right()
    inner_top = tv_inner_top()
    inner_bottom = tv_inner_bottom()

    function y_cornered()
        return logo.y - corner_distance_threshold <= inner_top or 
        logo.y + logo.height + corner_distance_threshold >= inner_bottom
    end

    function x_cornered()
        return logo.x - corner_distance_threshold <= inner_left or 
        logo.x + logo.width + corner_distance_threshold >= inner_right
    end

    if logo.x == inner_left then
        logo.x += 1
        bounce_state.x = 1
        bounce_state.hit_corner = bounce_state.hit_corner or y_cornered()
    end
    if logo.x + logo.width == inner_right then
        logo.x -= 1
        bounce_state.x = -1
        bounce_state.hit_corner = bounce_state.hit_corner or y_cornered()
    end
    if logo.y == inner_top then
        logo.y += 1
        bounce_state.y = 1
        bounce_state.hit_corner = bounce_state.hit_corner or x_cornered()
    end
    if logo.y + logo.height == inner_bottom then
        logo.y -= 1
        bounce_state.y = -1
        bounce_state.hit_corner = bounce_state.hit_corner or x_cornered()
    end

    return bounce_state
end


function maybe_play_bounce_sound()
    if stat(46) == -1 then
        sfx(0, 0)
    end
end

function maybe_play_score_sound()
    if stat(47) == -1 then
        sfx(1, 1)
    end
end

function maybe_move_square(dx, dy)
    new_x = tv.x + dx
    new_y = tv.y + dy

    if new_x < 0 or new_x + tv.width >= 128 then
        return false
    else
        tv.x += dx
    end

    if new_y < 0 or new_y + tv.height >= 128 then
        return false
    else
        tv.y += dy
    end
end

function _update()

    for btnpack in all({
        { b = 0, x = -1, y = 0 },
        { b = 1, x = 1, y = 0 },
        { b = 2, x = 0, y = -1 },
        { b = 3, x = 0, y = 1 }
    }) do
        if btnp(btnpack.b) then
            maybe_move_square(btnpack.x, btnpack.y)
        end
    end

    if btn(4) then
        frames_since_last_move += 1
        if frames_remaining_until_we_can_score > 0 then
            frames_remaining_until_we_can_score -= 1
        end

        if frames_since_last_move >= frames_between_each_move then
            frames_since_last_move = 0
            logo.x += pixels_for_each_move * logo.dx
            logo.y += pixels_for_each_move * logo.dy
        end

        logo_bounce_state = maybe_bounce_logo()
        sound = false

        if logo_bounce_state.x != 0 and logo_bounce_state.x != logo.dx then
            logo.dx *= -1
            sound = true
        end

        if logo_bounce_state.y != 0 and logo_bounce_state.y != logo.dy then
            logo.dy *= -1
            sound = true
        end

        if logo_bounce_state.hit_corner then
            if frames_remaining_until_we_can_score == 0 then
                score += 1
                frames_remaining_until_we_can_score = frames_between_each_score
                maybe_play_score_sound()
            end
        elseif sound then
            maybe_play_bounce_sound()
        end
    end
end

function render_tv()
    for i = 0, tv.thickness - 1 do
        rect(
            tv.x + i,
            tv.y + i,
            tv.x + tv.width - i,
            tv.y + tv.height - i,
            7
        )
    end

    rectfill(
        tv.x + tv.thickness,
        tv.y + tv.thickness,
        tv.x + tv.width - tv.thickness,
        tv.y + tv.height - tv.thickness,
        5
    )
end

function render_logo()
    spr(0, logo.x, logo.y, 4, 4)
end

function _draw()
    camera()
    cls(1)
    render_tv()
    render_logo()
    color()
    print("score: " .. score)
end