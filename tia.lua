
define_tile_code("forcefield_left")
define_tile_code("forcefield_left_top")
define_tile_code("forcefield_right")
define_tile_code("forcefield_right_top")
define_tile_code("back_jetpack")

local tia = {
    identifier = "tia",
    title = "Jetpack Challenge",
    theme = THEME.NEO_BABYLON,
    width = 3,
    height = 11,
    file_name = "tia.lvl",
}

local level_state = {
    loaded = false,
    callbacks = {},
}

local overall_state = {
    pb = 0,
    new_pb_callback = nil,
}

tia.set_pb_callback = function(callback)
    overall_state.new_pb_callback = callback
end

tia.set_pb = function(pb)
    overall_state.pb = pb
end

tia.load_level = function()
    if level_state.loaded then return end
    level_state.loaded = true
    local laser_timer = 0
    if options["disable_lasers"] then
        laser_timer = 1000000
    end
    level_state.callbacks[#level_state.callbacks+1] = set_pre_tile_code_callback(function(x, y, layer)
        local euid = spawn_entity(ENT_TYPE.FLOOR_HORIZONTAL_FORCEFIELD, x, y, layer, 0, 0)
        local e = get_entity(euid)
        e.timer = 120 + laser_timer
        e.flags = clr_flag(e.flags, ENT_FLAG.FACING_LEFT)
        return true
    end, "forcefield_left")
    level_state.callbacks[#level_state.callbacks+1] = set_pre_tile_code_callback(function(x, y, layer)
        local euid = spawn_entity(ENT_TYPE.FLOOR_HORIZONTAL_FORCEFIELD_TOP, x, y, layer, 0, 0)
        local e = get_entity(euid)
        e.flags = clr_flag(e.flags, ENT_FLAG.FACING_LEFT)
        return true
    end, "forcefield_left_top")
    level_state.callbacks[#level_state.callbacks+1] = set_pre_tile_code_callback(function(x, y, layer)
        local euid = spawn_entity(ENT_TYPE.FLOOR_HORIZONTAL_FORCEFIELD, x, y, layer, 0, 0)
        local e = get_entity(euid)
        e.timer = 60 + laser_timer
        e.flags = set_flag(e.flags, ENT_FLAG.FACING_LEFT)
        return true
    end, "forcefield_right")
    level_state.callbacks[#level_state.callbacks+1] = set_pre_tile_code_callback(function(x, y, layer)
        local euid = spawn_entity(ENT_TYPE.FLOOR_HORIZONTAL_FORCEFIELD_TOP, x, y, layer, 0, 0)
        local e = get_entity(euid)
        e.flags = set_flag(e.flags, ENT_FLAG.FACING_LEFT)
        return true
    end, "forcefield_right_top")
    local jetpack
    level_state.callbacks[#level_state.callbacks+1] = set_callback(function()
        if #players < 1 then return end
        local euid = spawn_entity(ENT_TYPE.ITEM_JETPACK, 0, 0, LAYER.PLAYER, 0, 0)
        jetpack = get_entity(euid)
        pick_up(players[1].uid, euid)
    end, ON.LEVEL)
    local ground_level = 69.05
    local extra_height = 0
    local max_height = 0
    level_state.callbacks[#level_state.callbacks+1] = set_callback(function()
        if #players < 1 then return end
        local player = players[1]
        if not player then return end
        local x, y, layer = get_render_position(player.uid)
        if y > 110 then
            extra_height = extra_height + 24
            player.y = player.y - 24
            state.camera.focus_y = state.camera.focus_y - 24
            state.camera.adjusted_focus_y = state.camera.adjusted_focus_y - 24
        elseif y <= ground_level + 1 then
            extra_height = 0
        end
    end, ON.GAMEFRAME)
    level_state.callbacks[#level_state.callbacks+1] = set_callback(function(ctx)
        if #players < 1 then return end
        local player = players[1]
        local height = extra_height + player.y - ground_level
        if height > max_height and player.health > 0 then
            max_height = height
            if height > overall_state.pb then
                overall_state.pb = height
                if overall_state.new_pb_callback then
                    overall_state.new_pb_callback(height)
                end
            end
        end
        local text = f'Max height: {string.format("%.2f", max_height)}    PB: {string.format("%.2f", overall_state.pb)}'
        local tw, th = draw_text_size(30, text)
        ctx:draw_text(0 - tw / 2, -0.935, 30, text, rgba(255, 255, 255, 195))
    end, ON.GUIFRAME)
    level_state.callbacks[#level_state.callbacks+1] = set_callback(function(ctx, draw_depth)
        if #players < 1 or extra_height > 0 then return end
        if draw_depth == players[1].type.draw_depth then
            for i=0,12 do
                local column = 0
                if i % 2 == 0 then
                    column = 1
                end
                local rect2 = AABB:new(2.5 + i, 69 + 21.5, 3.5 + i, 69 + 20.5)

                local rect3 = AABB:new(35 - (3.5 + i), 69 + 21.5, 35 - (2.5 + i), 69 + 20.5)
                if i == 12 then
                    ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_FLOORMISC_0, 6, 5, rect2, Color:white())
                    ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_FLOORMISC_0, 6, 5, rect3, Color:white())
                else
                    ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_BORDER_MAIN_0, 7, column, rect2, Color:white())
                    ctx:draw_world_texture(TEXTURE.DATA_TEXTURES_BORDER_MAIN_0, 7, column, rect3, Color:white())
                end
            end
        end
    end, ON.RENDER_PRE_DRAW_DEPTH)
    level_state.callbacks[#level_state.callbacks+1] = set_post_entity_spawn(function(entity)
        entity.flags = set_flag(entity.flags, ENT_FLAG.INVISIBLE)
    end, SPAWN_TYPE.ANY, 0, ENT_TYPE.BG_LEVEL_SHADOW)
end

tia.unload_level = function()
    if not level_state.loaded then return end

    local callbacks_to_clear = level_state.callbacks
    level_state.loaded = false
    level_state.callbacks = {}
    for _, callback in pairs(callbacks_to_clear) do
        clear_callback(callback)
    end
end

return tia
