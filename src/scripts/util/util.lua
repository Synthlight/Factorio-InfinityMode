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

-- close open_gui on escape
on_event(defines.events.on_gui_closed, function(e)
    local player = util.get_player(e)
    local player_table = util.player_table(player)
    local open_gui = player_table.open_gui
    if open_gui and open_gui.element == e.element then
        open_gui.element.destroy()
        if player_table[open_gui.data_to_destroy] then
            player_table[open_gui.data_to_destroy] = nil
        end
        player_table.open_gui = nil
    end
end)

-- handle open_gui close buttons
on_event(defines.events.on_gui_click, function(e)
    local player = util.get_player(e)
    local open_gui = util.player_table(player).open_gui
    if open_gui and open_gui.close_button and open_gui.close_button == e.element then
        open_gui.element.destroy()
        open_gui = nil
    end
end)

function util.set_open_gui(player, element, close_button, data_to_destroy)
    util.player_table(player).open_gui = {
        element = element,
        location = element.location,
        close_button = close_button or nil,
        data_to_destroy = data_to_destroy or nil
    }
    player.opened = element
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

function util.cheat_table(category, name, obj)
    if category == 'game' then return global.cheats[category][name] end
    return obj and global.cheats[category][name][obj.index] or global.cheats[category][name]
end

function util.cheat_enabled(category, name, index, exclude_idx)
    local cheat_table = table.deepcopy(util.cheat_table(category, name))
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