meta = {
    name = 'Jetpack Challenge',
    version = '1.0',
    description = 'See how high you can fly',
    author = 'JayTheBusinessGoose',
}

local level_sequence = require('LevelSequence/level_sequence')
local SIGN_TYPE = level_sequence.SIGN_TYPE
local tia = require('tia')

level_sequence.set_levels({tia})

local lvl_state = {
    pb = 0,
}

tia.set_pb_callback(function(pb)
    lvl_state.pb = pb
end)

level_sequence.set_on_post_level_generation(function(level)
    if #players == 0 then return end

    players[1].inventory.bombs = 0
    players[1].inventory.ropes = 0
    players[1].health = 1
end)

set_callback(function()
    level_sequence.activate()
end, ON.LOAD)

set_callback(function()
    level_sequence.activate()
end, ON.SCRIPT_ENABLE)

set_callback(function()
    level_sequence.deactivate()
end, ON.SCRIPT_DISABLE)

set_ghost_spawn_times(-1, -1)

set_callback(function(ctx)
    local load_data_str = ctx:load()
    if load_data_str ~= '' then
        local load_data = json.decode(load_data_str)
        if load_data.pb then
            lvl_state.pb = load_data.pb
            tia.set_pb(lvl_state.pb)
        end
    end
end, ON.LOAD)

set_callback(function(ctx)
    local save_data = {
        version = '1.0',
        pb = lvl_state.pb,
    }
    ctx:save(json.encode(save_data))
end, ON.SAVE)

set_callback(function(ctx)
    if #players < 1 then return end
    local player = players[1]
    if (not player) or state.theme ~= THEME.BASE_CAMP then return end
    if lvl_state.pb == 0 then return end
    local text = f'PB: {string.format("%.2f", lvl_state.pb)}'
    local tw, th = draw_text_size(30, text)
    ctx:draw_text(0 - tw / 2, -0.935, 30, text, rgba(255, 255, 255, 195))
end, ON.GUIFRAME)