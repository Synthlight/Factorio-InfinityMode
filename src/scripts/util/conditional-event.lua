-- ----------------------------------------------------------------------------------------------------
-- CONDITIONAL EVENT HANDLER
-- This script creates and handles conditional events.

local abs = math.abs
local event = require('__stdlib__/stdlib/event/event')
local string = require('__stdlib__/stdlib/utils/string')
local table = require('__stdlib__/stdlib/utils/table')

local util = require('scripts/util/util')

local conditional_event = {}

-- all conditional events are contained here to enable lookup
local events_def = {
    cheats = {
        player = {
            instant_blueprint = {
                on_built_entity = {{defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built}, function(e)
                    if not e.player_index then return end
                    if not util.cheat_enabled('player', 'instant_blueprint', e.player_index) then return end
                    local entity = e.created_entity or e.entity
                    local cheat_table = util.cheat_table('player', 'instant_blueprint', e.player_index)
                    if util.is_ghost(entity) then
                        -- attempt to revive the ghost
                        if not entity.revive{raise_revive=true} then
                            -- if the table is empty, register the on_tick event
                            if #cheat_table.next_tick_entities == 0 then
                                conditional_event.register('cheats.player.instant_blueprint.next_tick')
                            end
                            -- add the entity to the table
                            table.insert(cheat_table.next_tick_entities, {tries=1, entity=entity})
                        end
                    end
                end},
                next_tick = {{defines.events.on_tick}, function(e)
                    local cheat_parent = util.cheat_table('player', 'instant_blueprint')
                    local deregister = true
                    -- since on_tick does not have a player_index, we must iterate over every player's table
                    for _,cheat_table in pairs(cheat_parent) do
                        -- check if the table has contents
                        if #cheat_table.next_tick_entities > 0 then
                            -- for each entity in the table
                            for i,t in pairs(cheat_table.next_tick_entities) do
                                -- try to revive the entity and act on the result
                                if t.entity.revive{raise_revive=true} then
                                    cheat_table.next_tick_entities[i] = nil
                                else
                                    t.tries = t.tries + 1
                                    -- after ten tries, remove the entity from the table
                                    if t.tries >= 10 then
                                        log('Unable to revive entity at position '..serpent.line(t.entity.position)..', deregistering')
                                        cheat_table.next_tick_entities[i] = nil
                                    end
                                    deregister = false
                                end
                            end     
                        end
                    end
                    -- if all entites have been revived or deregistered, deregister this event
                    if deregister then
                        conditional_event.deregister('cheats.player.instant_blueprint.next_tick')
                    end
                end}
            },
            instant_upgrade = {
                on_marked_for_upgrade = {{defines.events.on_marked_for_upgrade}, function(e)
                    if not e.player_index then return end
                    if not util.cheat_enabled('player', 'instant_upgrade', e.player_index) then return end
                    local entity = e.entity
                    -- game.print('upgrading entity ' .. entity.name .. ' at position ' .. entity.position.x .. ',' .. entity.position.y .. ' to: ' .. e.target.name)
                    entity.surface.create_entity{
                        name = e.target.name,
                        position = entity.position,
                        direction = entity.direction or nil,
                        force = entity.force,
                        fast_replace = true,
                        spill = false,
                        raise_built = true
                    }
                end}
            },
            instant_deconstruction = {
                on_deconstruction = {{defines.events.on_marked_for_deconstruction}, function(e)
                    if not e.player_index then return end
                    if not util.cheat_enabled('player', 'instant_deconstruction', e.player_index) then return end
                    local entity = e.entity
                    local cheat_table = util.cheat_table('player', 'instant_deconstruction', e.player_index)
                    -- attempt to destroy the entity
                    if not entity.destroy{do_cliff_correction=true, raise_destroy=true} then
                        -- if the table is empty, register the on_tick event
                        if #cheat_table.next_tick_entities == 0 then
                            conditional_event.register('cheats.player.instant_deconstruction.next_tick')
                        end
                        -- add the entity to the table
                        table.insert(cheat_table.next_tick_entities, {tries=1, entity=entity})
                    end
                end},
                next_tick = {{defines.events.on_tick}, function(e)
                    local cheat_parent = util.cheat_table('player', 'instant_deconstruction')
                    local deregister = true
                    -- since on_tick does not have a player_index, we must iterate over every player's table
                    for _,cheat_table in pairs(cheat_parent) do
                        -- check if the table has contents
                        if #cheat_table.next_tick_entities > 0 then
                            -- for each entity in the table
                            for i,t in pairs(cheat_table.next_tick_entities) do
                                -- try to revive the entity and act on the result
                                if t.entity.destroy{do_cliff_correction=true, raise_destroy=true} then
                                    cheat_table.next_tick_entities[i] = nil
                                else
                                    t.tries = t.tries + 1
                                    -- after ten tries, remove the entity from the table
                                    if t.tries >= 10 then
                                        log('Unable to destroy entity at position '..serpent.line(t.entity.position)..', deregistering')
                                        cheat_table.next_tick_entities[i] = nil
                                    end
                                    deregister = false
                                end
                            end     
                        end
                    end
                    -- if all entites have been revived or deregistered, deregister this event
                    if deregister then
                        conditional_event.deregister('cheats.player.instant_deconstruction.next_tick')
                    end
                end}
            },
            keep_last_item = {
                on_put_item = {{defines.events.on_put_item}, function(e)
                    local player = util.get_player(e)
                    if not util.cheat_enabled('player', 'keep_last_item', player.index) then return end
                    local cursor_stack = player.cursor_stack
                    if cursor_stack.valid_for_read and cursor_stack.count == 1 then
                        player.get_main_inventory().insert{name=cursor_stack.name, count=cursor_stack.count}
                    end
                end}
            },
            repair_damaged_item = {
                on_main_inv_changed = {{defines.events.on_player_main_inventory_changed}, function(e)
                    local player = util.get_player(e)
                    if not util.cheat_enabled('player', 'repair_damaged_item', player.index) then return end
                    local inventory = player.get_main_inventory()
                    -- iterate over every slot in the inventory, repairing any damaged items
                    for i=1,#inventory do
                        if inventory[i].valid_for_read and inventory[i].durability then inventory[i].add_durability(1000000) end
                        -- there is currently no way to get the max ammo for an ammoitem, and simply setting it to 1000000 will cause additional items to be created
                        -- if inventory[i].valid_for_read and inventory[i].type == 'ammo' then inventory[i].add_ammo(1000000) end
                    end
                end},
                on_cursor_stack_changed = {{defines.events.on_player_cursor_stack_changed}, function(e)
                    
                end},
                on_tick = {{defines.events.on_tick}, function(e)
                    
                end}
            },
            instant_request = {
                on_main_inventory_changed = {{defines.events.on_player_main_inventory_changed}, function(e)
                    local player = util.get_player(e)
                    if not util.cheat_enabled('player', 'instant_request', player.index) then return end
                    -- check if the player has a character
                    if not player.character then return end
                    local character = player.character
                    local inventory = player.get_main_inventory()
                    local contents = inventory.get_contents()
                    -- combine the cursor stack with the main inventory contents
                    if player.cursor_stack.valid_for_read then
                        local stack = player.cursor_stack
                        contents[stack.name] = stack.count + (contents[stack.name] or 0)
                    end
                    -- iterate over all request slots
                    for i=1,character.request_slot_count do
                        local request = character.get_request_slot(i)
                        if request then
                            -- subtract request from the actual count
                            local diff = request.count - (contents[request.name] or 0)
                            if diff > 0 then
                                inventory.insert{name=request.name, count=diff}
                            end
                        end
                    end
                end}
            },
            instant_trash = {
                on_trash_inventory_changed = {{defines.events.on_player_trash_inventory_changed}, function(e)
                    local player = util.get_player(e)
                    if not util.cheat_enabled('player', 'instant_trash', player.index) then return end
                    -- check if the player has a character
                    if not player.character then return end
                    player.character.get_inventory(defines.inventory.character_trash).clear()
                end}
            }
        },
        force = {
            instant_research = {
                on_research_started = {{defines.events.on_research_started}, function(e)
                    local research = e.research
                    local force = research.force
                    if not util.cheat_enabled('force', 'instant_research', force.index) then return end
                    force.research_progress = 1
                end}
            }
        },
        surface = {
            
        }
    },
    infinity_wagon = {
        on_tick = {{defines.events.on_tick}, function(e)
            for _,t in pairs(global.wagons) do
                if t.wagon.valid and t.ref.valid then
                    if t.wagon_name == 'infinity-cargo-wagon' then
                        if t.flip == 0 then
                            t.wagon_inv.clear()
                            for n,c in pairs(t.ref_inv.get_contents()) do t.wagon_inv.insert{name=n, count=c} end
                            t.flip = 1
                        elseif t.flip == 1 then
                            t.ref_inv.clear()
                            for n,c in pairs(t.wagon_inv.get_contents()) do t.ref_inv.insert{name=n, count=c} end
                            t.flip = 0
                        end
                    elseif t.wagon_name == 'infinity-fluid-wagon' then
                        if t.flip == 0 then
                            local fluid = t.ref_fluidbox[1]
                            t.wagon_fluidbox[1] = fluid and {name=fluid.name, amount=(abs(fluid.amount) * 250), temperature=fluid.temperature} or nil
                            t.flip = 1
                        elseif t.flip == 1 then
                            local fluid = t.wagon_fluidbox[1]
                            t.ref_fluidbox[1] = fluid and {name=fluid.name, amount=(abs(fluid.amount) / 250), temperature=fluid.temperature} or nil
                            t.flip = 0
                        end
                    end
                end
            end
        end}
    }
}

local function get_object(string)
    local def = events_def
    for _,key in pairs(string.split(string)) do
        def = def[key]
    end
    return def
end

event.on_init(function()
    global.events = {}
end)

event.on_load(function()
    for e,t in pairs(global.events) do
        for def,_ in pairs(t) do
            conditional_event.register(def)
        end
    end
end)

-- handler must be a function reference from the definitions file
function conditional_event.register(def)
    local events = global.events
    local object = get_object(def)
    for i,e in pairs(object[1]) do
        if not events[e] then events[e] = {} end
        if not events[e][def] then
            events[e][def] = true
        end
        event.register(e, object[2])
    end
end

function conditional_event.deregister(def)
    local events = global.events
    local object = get_object(def)
    for i,e in pairs(object[1]) do
        if events[e] == nil then return end
        events[e][def] = nil
        if table_size(events[e]) == 0 then events[e] = nil end
        event.remove(e, object[2])
    end
end

-- only register if nobody else has the cheat active
function conditional_event.cheat_register(obj, cheat_def, event_def)
    local string_table = string.split(event_def)
    if not util.cheat_enabled(string_table[2], string_table[3], nil, obj.index) then
        conditional_event.register(event_def)
    end
end

function conditional_event.cheat_deregister(obj, cheat_def, event_def)
    local string_table = string.split(event_def)
    if not util.cheat_enabled(string_table[2], string_table[3], nil, obj.index) then
        conditional_event.deregister(event_def)
    end
end

return conditional_event