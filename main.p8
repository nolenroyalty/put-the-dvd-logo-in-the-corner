-- THE GAME: shoot the DVD logo into the corner

-- TODO:
-- * DRAW ALL CORNERS
-- * SHRINK EACH CORNER WHEN IT IS HIT
-- * START WITH THE SCREEN A LITTLE SMALLER
-- * GROW SCREEN AND INCREASE LOGO SPEED OVER TIME

function _init()
    logo = { x = 64, y = 26, width = 32, height = 32, thickness = 1, dx = 1, dy = 1, x_movement = 1, y_movement = 1 }
    tv = { x = 10, y = 10, width = 108, height = 108, thickness = 3 }

    frames_since_last_move = 0
    frames_between_each_move = 1
    pixels_for_each_move = 1

    corner_distance_threshold = 6
    thresholds = { ne=corner_distance_threshold, nw=corner_distance_threshold, se=corner_distance_threshold, sw=corner_distance_threshold }
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
        return logo.y - corner_distance_threshold <= inner_top
                or logo.y + logo.height + corner_distance_threshold >= inner_bottom
    end

    function x_cornered()
        return logo.x - corner_distance_threshold <= inner_left
                or logo.x + logo.width + corner_distance_threshold >= inner_right
    end

    if logo.x <= inner_left then
        logo.x = inner_left + 1
        -- logo.x += 1
        bounce_state.x = 1
        bounce_state.hit_corner = bounce_state.hit_corner or y_cornered()
    end
    if logo.x + logo.width >= inner_right then
        logo.x = inner_right - logo.width - 1
        -- logo.x -= 1
        bounce_state.x = -1
        bounce_state.hit_corner = bounce_state.hit_corner or y_cornered()
    end
    if logo.y <= inner_top then
        -- logo.y += 1
        logo.y = inner_top + 1
        bounce_state.y = 1
        bounce_state.hit_corner = bounce_state.hit_corner or x_cornered()
    end
    if logo.y + logo.height >= inner_bottom then
        -- logo.y -= 1
        logo.y = inner_bottom - logo.height - 1
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

    if btnp(5) then
        logo.dx *= -1
        logo.dy *= -1
    end

    if btn(4) then
        frames_since_last_move += 1
        if frames_remaining_until_we_can_score > 0 then
            frames_remaining_until_we_can_score -= 1
        end

        if frames_since_last_move >= frames_between_each_move then
            frames_since_last_move = 0
            logo.x += pixels_for_each_move * logo.dx * logo.x_movement
            logo.y += pixels_for_each_move * logo.dy * logo.y_movement
        end

        logo_bounce_state = maybe_bounce_logo()
        sound = false

        if logo_bounce_state.x != 0 and logo_bounce_state.x != logo.dx then
            logo.dx *= -1
            logo.x_movement = 2
            logo.y_movement = 1
            sound = true
        end

        if logo_bounce_state.y != 0 and logo_bounce_state.y != logo.dy then
            logo.dy *= -1
            logo.x_movement = 1
            logo.y_movement = 2
            sound = true
        end

        if logo_bounce_state.hit_corner then
            if frames_remaining_until_we_can_score == 0 then
                score += 1
                frames_remaining_until_we_can_score = frames_between_each_score
                if corner_distance_threshold > 1 then
                    corner_distance_threshold -= 1
                end
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

    color(9)
    right = tv_inner_right()
    left = tv_inner_left()
    top = tv_inner_top()
    bottom = tv_inner_bottom()

    -- NORTHWEST
    rectfill(left - tv.thickness + 1, top + thresholds.sw, left, top - tv.thickness + 1)
    rectfill(left - tv.thickness + 1, top, left + thresholds.sw, top - tv.thickness + 1)
    
    -- NORTHEAST
    rectfill(right - thresholds.ne, top, right + tv.thickness - 1, top - tv.thickness + 1)
    rectfill(right, top + thresholds.se, right + tv.thickness - 1, top - tv.thickness + 1)

    -- SOUTHWEST
    rectfill(left - tv.thickness + 1, bottom - thresholds.sw, left, bottom + tv.thickness - 1)
    rectfill(left - tv.thickness + 1, bottom, left + thresholds.sw, bottom + tv.thickness - 1)

    -- SOUTHEAST
    rectfill(right - thresholds.se, bottom, right + tv.thickness - 1, bottom + tv.thickness - 1)
    rectfill(right, bottom - thresholds.se, right + tv.thickness - 1, bottom + tv.thickness - 1)
    color()
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
    can_score = "no"
    if frames_remaining_until_we_can_score <= 0
    then can_score = "yes"
    end

    print(logo.x .. " | " .. logo.x + logo.width .. " | " .. tv_inner_right() - corner_distance_threshold .. " | " .. can_score, 0, 123)
end