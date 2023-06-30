-- THE GAME: shoot the DVD logo into the corner

function reset_to_initial_values()
    logo = { x = 50, y = 50, width = 32, height = 32, thickness = 1, dx = 1, dy = 1, x_movement = 1, y_movement = 1 }
    tv = { x = 20, y = 30, width = 90, height = 67, thickness = 3 }

    states = { "waiting", "playing", "game-over" }
    state = 1

    frames_since_last_move = 0
    frames_between_each_move = 2
    pixels_for_each_move = 1

    corner_distance_threshold = 2
    thresholds = { ne = corner_distance_threshold, nw = corner_distance_threshold, se = corner_distance_threshold, sw = corner_distance_threshold }
    frames_between_each_score = 15
    frames_remaining_until_we_can_score = 0
    score = 0

    frames_until_timer_tick = 30
    timer = 45

    frames_to_flash_green_for = 10
    flash_green_for_this_many_frames = 0

    sparks = {}
    debug = true
end

function _init()
    reset_to_initial_values()
end

function set_waiting()
    state = 1
end

function set_playing()
    state = 2
end

function set_game_over()
    state = 3
end

function randsign()
    if rnd(1) < 0.5 then
        return -1
    else
        return 1
    end
end

function tv_inner_left()
    return flr(tv.x + tv.thickness - 1)
end

function tv_inner_right()
    return flr(tv.x + tv.width - tv.thickness + 1)
end

function tv_inner_top()
    return flr(tv.y + tv.thickness - 1)
end

function tv_inner_bottom()
    return flr(tv.y + tv.height - tv.thickness + 1)
end

function maybe_bounce_logo()
    bounce_state = { x = 0, y = 0, hit_corner = false }
    inner_left = tv_inner_left()
    inner_right = tv_inner_right()
    inner_top = tv_inner_top()
    inner_bottom = tv_inner_bottom()

    -- It's a little hard to think about, but we need to use <= for north and west
    -- but > for south and east. This is because a pixel has a size of...1 by 1 pixel,
    -- and that size is drawn from the top left corner of the pixel - so there's an implicit
    -- 1 that we're adding for our north / east comparisons. ugh. I can't explain
    -- this without a diagram.

    function nw()
        t = thresholds.nw
        return logo.x - t <= inner_left and logo.y - t <= inner_top
    end

    function ne()
        t = thresholds.ne
        return logo.x + logo.width + t > inner_right and logo.y - t <= inner_top
    end

    function sw()
        t = thresholds.sw
        return logo.x - t <= inner_left and logo.y + logo.height + t > inner_bottom
    end

    function se()
        t = thresholds.se
        return logo.x + logo.width + t > inner_right and logo.y + logo.height + t > inner_bottom
    end

    if logo.x <= inner_left then
        logo.x = inner_left + 1
        bounce_state.x = 1
    end
    if logo.x + logo.width > inner_right then
        logo.x = inner_right - logo.width - 1
        bounce_state.x = -1
    end
    if logo.y <= inner_top then
        logo.y = inner_top + 1
        bounce_state.y = 1
    end
    if logo.y + logo.height > inner_bottom then
        logo.y = inner_bottom - logo.height - 1
        bounce_state.y = -1
    end

    bounced = bounce_state.x != 0 or bounce_state.y != 0

    if bounced and nw() then 
        bounce_state.hit_corner = "nw"
        logo.x = inner_left + 1
        logo.y = inner_top + 1
     end
    if bounced and ne() then 
        bounce_state.hit_corner = "ne"
        logo.x = inner_right - logo.width - 1
        logo.y = inner_top + 1 
    end
    if bounced and sw() then 
        bounce_state.hit_corner = "sw"
        logo.x = inner_left + 1
        logo.y = inner_bottom - logo.height - 1
     end
    if bounced and se() then 
        bounce_state.hit_corner = "se"
        logo.x = inner_right - logo.width - 1
        logo.y = inner_bottom - logo.height - 1
    end

    return bounce_state
end

function maybe_play_bounce_sound()
    if stat(46) == -1 then
        sfx(0, 0)
    end
end

function play_score_sound()
    sfx(1, 0)
end

function try_to_move_tv(dx, dy)
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

function handle_tv_input()
    for btnpack in all({
        { b = 0, x = -1, y = 0 },
        { b = 1, x = 1, y = 0 },
        { b = 2, x = 0, y = -1 },
        { b = 3, x = 0, y = 1 }
    }) do
        if btn(btnpack.b) then
            try_to_move_tv(btnpack.x, btnpack.y)
        end
    end
end

function handle_rewind()
    if debug and btnp(5) then
        logo.dx *= -1
        logo.dy *= -1
    end
end

function grow_left(amount)
    tv.x -= amount
    tv.width += amount
end

function grow_right(amount)
    tv.width += amount
end

function grow_up(amount)
    tv.y -= amount
    tv.height += amount
end

function grow_down(amount)
    tv.height += amount
end

function make_spark(corner)
    x = 0
    y = 0
    dx = 0
    dy = 0
    move_amount = 1 + flr(rnd(2))

    if corner == "nw" then
        x = tv.x
        y = tv.y
        dx = -move_amount
        dy = -move_amount
    elseif corner == "ne" then
        x = tv.x + tv.width + tv.thickness - 1
        y = tv.y
        dx = move_amount
        dy = -move_amount
    elseif corner == "sw" then
        x = tv.x
        y = tv.y + tv.height + tv.thickness - 1
        dx = -move_amount
        dy = move_amount
    elseif corner == "se" then
        x = tv.x + tv.width + tv.thickness - 1
        y = tv.y + tv.height + tv.thickness - 1
        dx = move_amount
        dy = move_amount
    end

    random_amount = 6
    x += flr(rnd(random_amount)) * randsign()
    y += flr(rnd(random_amount)) * randsign()

    spark = {x = x, y=y, dx=dx, dy=dy, frames_remaining=10}

    add(sparks, spark)
end

function handle_grow(corner)
    horizontal_amount = 2
    function grow_horizontal_if_possible(direction, recurse)
        if direction == "L" then
            if tv.x - horizontal_amount >= 0 then grow_left(horizontal_amount)
            elseif recurse then grow_horizontal_if_possible("R", false)
            else return false
            end
        elseif direction == "R" then
            if tv.x + tv.width + horizontal_amount < 128 then
                grow_right(horizontal_amount)
            elseif recurse then grow_horizontal_if_possible("L", false)
            else return false
            end
        end
    end

    function grow_vertical_if_possible(direction, amount, recurse)
        if direction == "U" then
            if tv.y - amount >= 0 then grow_up(amount)
            elseif recurse then grow_vertical_if_possible("D", amount, false)
            else return false
            end
        elseif direction == "D" then
            if tv.y + tv.height + amount < 128 then grow_down(amount)
            elseif recurse then grow_vertical_if_possible("U", amount, false)
            else return false
            end
        end
    end

    vertical_amount_to_grow = flr(0.75 * (tv.width + horizontal_amount)) - tv.height
    
    hdirection = sub(corner, 1, 1) == "W" and "R" or "L"
    vdirection = sub(corner, 2, 2) == "N" and "D" or "U"

    if grow_horizontal_if_possible(hdirection, true) then
        grow_vertical_if_possible(vdirection, vertical_amount_to_grow, true)
    end
end

function handle_incr_score(corner)
    score += 1
    if thresholds[corner] > 2 then thresholds[corner] -= 1 end

    if score == 5 then
        frames_between_each_move = 1
    elseif score % 5 == 0 then
        pixels_for_each_move += 1
    elseif score % 2 == 0 then
        handle_grow(corner)
    end

    number_of_sparks = 7 + 2 * flr(score / 5)
    for i = 1, number_of_sparks do
        make_spark(corner)
    end

    flash_green_for_this_many_frames = frames_to_flash_green_for
    play_score_sound()
end

function handle_move_logo()
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
            handle_incr_score(logo_bounce_state.hit_corner)
            frames_remaining_until_we_can_score = frames_between_each_score
        end
    elseif sound then
        maybe_play_bounce_sound()
    end
end

function handle_move_sparks()
    s = {}
    for spark in all(sparks) do
        spark.x += spark.dx
        spark.y += spark.dy
        
        move_amount = 3
        spark.x += flr(rnd(move_amount)) * randsign()
        spark.y -= flr(rnd(move_amount)) * randsign()

        spark.frames_remaining -= 1
        if spark.frames_remaining > 0 then
            add(s, spark)
        end
    end
    sparks = s
end

function handle_decr_timer()
    frames_until_timer_tick -= 1

    if frames_until_timer_tick <= 0 then
        frames_until_timer_tick = 30
        timer -= 1
    end
end

function render_tv()
    right = tv_inner_right()
    left = tv_inner_left()
    top = tv_inner_top()
    bottom = tv_inner_bottom()

    -- Grey border (unless we just scored)
    if flash_green_for_this_many_frames > 0 then
        color(3)
        flash_green_for_this_many_frames -= 1
    else
        color(5)
    end
    for i = 0, tv.thickness - 1 do
        rect(
            tv.x + i,
            tv.y + i,
            tv.x + tv.width - i,
            tv.y + tv.height - i
        )
    end

    -- Grey TV
    color(5)
    xoffset = 10
    tvboxheight = 12
    rectfill(
        left + xoffset,
        tv.y + tv.height + 1,
        right - xoffset,
        -- tv.x + tv.width - tv.thickness - xoffset - 1,
        tv.y + tv.height + tvboxheight
    )

    color(0)
    button_start = 5
    ovalfill(
        right - xoffset - 10,
        tv.y + tv.height + button_start,
        right - xoffset - 6,
        tv.y + tv.height + button_start + 2
    )

    rectfill(
        left + xoffset + 7,
        tv.y + tv.height + 4,
        left + xoffset + 35,
        tv.y + tv.height + 8
    )

    -- Black interior
    color(0)
    rectfill(
        tv.x + tv.thickness,
        tv.y + tv.thickness,
        tv.x + tv.width - tv.thickness,
        tv.y + tv.height - tv.thickness
    )

    -- Light grey corners
    if flash_green_for_this_many_frames > 0 then
        color(11)
    else
        color(9)
    end

    -- NORTHWEST
    rectfill(left - tv.thickness + 1, top + thresholds.nw, left, top - tv.thickness + 1)
    rectfill(left - tv.thickness + 1, top, left + thresholds.nw, top - tv.thickness + 1)

    -- NORTHEAST
    rectfill(right - thresholds.ne, top, right + tv.thickness - 1, top - tv.thickness + 1)
    rectfill(right, top + thresholds.ne, right + tv.thickness - 1, top - tv.thickness + 1)

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

function render_sparks()
    for spark in all(sparks) do
        color(9)
        rectfill(spark.x, spark.y, spark.x + 1, spark.y + 1)
        color()
    end
end

function handle_update_waiting()
    if btnp(4) then
        set_playing()
    end

    if debug then
        handle_tv_input()
        handle_rewind()
    end
end

function handle_update_playing()
    if btnp(4) then
        set_waiting()
    end

    handle_tv_input()
    handle_rewind()
    handle_move_logo()
    handle_move_sparks()
    handle_decr_timer()

    if timer <= 0 then
        set_game_over()
    end
end

function handle_update_game_over()
    if btnp(4) then
        reset_to_initial_values()
        set_playing()
    end
end

function _update()
    s = states[state]
    if s == "waiting" then
        handle_update_waiting()
    elseif s == "playing" then
        handle_update_playing()
    elseif s == "game-over" then
        handle_update_game_over()
    end
end

function _draw()
    camera()
    cls(1)
    render_tv()
    render_logo()
    render_sparks()
    color()
    if flash_green_for_this_many_frames > 0 then
        color(11)
    else
        color(6)
    end
    print("score: " .. score, 1, 1)
    color(6)
    print("time: " .. timer, 96, 1)
    color()
    -- can_score = "no"
    -- if frames_remaining_until_we_can_score <= 0 then
    --     can_score = "yes"
    -- end

    -- print(logo.x .. " | " .. logo.x + logo.width .. " | " .. tv_inner_right() - corner_distance_threshold .. " | " .. can_score, 0, 123)
end