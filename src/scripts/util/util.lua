local on_event = require('__stdlib__/stdlib/event/event').register
local table = require('__stdlib__/stdlib/utils/table')

local util = {}

-- ----------------------------------------------------------------------------------------------------
-- GENERAL

function util.get_player(obj)
    if obj.player_index then return game.players[obj.player_index] end
end

function util.is_player_god(player)
    return player.controller_type == defines.controllers.god
end

function util.is_ghost(obj)
    return obj.name == 'entity-ghost' or obj.name == 'tile-ghost'
end

-- ----------------------------------------------------------------------------------------------------
-- GUI

-- close center GUI on escape
on_event(defines.events.on_gui_closed, function(e)
    local player = util.get_player(e)
    local center_gui = util.get_center_gui(player)
    if center_gui and center_gui.element == e.element then
        util.close_center_gui(player)
    end
end)

-- handle window close buttons
on_event(defines.events.on_gui_click, function(e)
    local player = util.get_player(e)
    local element = e.element
    local center_gui = util.get_center_gui(player)
    if center_gui and center_gui.close_button == element then
        util.close_center_gui(player)
    end
end)

function util.set_center_gui(player, data, keep_previous)
    -- data table must contain ELEMENT, which is the root element of the open GUI (the frame, most of the time)
    -- other data is specific to each gui
    local global_data = util.get_center_gui(player)
    -- if another gui is currently open, destroy it
    if global_data and not keep_previous then
        global_data.element.destroy()
    end
    util.player_table(player).center_gui = data
    player.opened = data.element
end

function util.get_center_gui(player)
    return util.player_table(player).center_gui
end

function util.close_center_gui(player)
    local player_table = util.player_table(player)
    player_table.center_gui.element.destroy()
    player_table.center_gui = nil
    player.opened = nil
end

-- ----------------------------------------------------------------------------------------------------
-- GLOBAL

on_event('on_init', function(e)
    global.players = {}
    global.cheats = {}
end)

on_event(defines.events.on_player_created, function(e)
    local data = {}
    global.players[e.player_index] = data
end)

function util.player_table(player)
    if type(player) == 'number' then
        return global.players[player]
    end
    return global.players[player.index]
end

function util.cheat_table(category, name, index)
    return index and global.cheats[category][name][index] or global.cheats[category][name]
end

function util.cheat_enabled(category, name, index, exclude_idx)
    local cheat_table = table.deepcopy(util.cheat_table(category, name))
    -- LOG{category .. '.' .. name, cheat_table}
    if exclude_idx then cheat_table[exclude_idx] = nil end
    if index then
        return cheat_table[index].cur_value
    else
        -- check if any players have the cheat enabled
        return table.any(cheat_table, function(data) return data.cur_value end)
    end
end

-- ----------------------------------------------------------------------------------------------------
-- INVENTORIES

-- Transfers the contents of the source inventory to the destination inventory.
function util.transfer_inventory_contents(source_inventory, destination_inventory)
	for i = 1, math.min(#source_inventory, #destination_inventory), 1 do
		local source_slot = source_inventory[i]
		if source_slot.valid_for_read then
			if destination_inventory[i].set_stack(source_slot) then
				source_inventory[i].clear()
			end
		end
	end
end

-- ----------------------------------------------------------------------------------------------------

return util