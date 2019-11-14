-- ----------------------------------------------------------------------------------------------------
-- TESSERACT CHEST CONTROL SCRIPTING

local event = require('__stdlib__/stdlib/event/event')
local on_event = event.register
local chest_names = {'tesseract-chest','tesseract-chest-passive-provider','tesseract-chest-storage'}

-- ----------------------------------------------------------------------------------------------------
-- UTILITIES

-- set the filters for the given tesseract chest
local function update_chest_filters(entity)
    entity.remove_unfiltered_items = true
    -- set infinity filters
    local i = 0
    for n,ss in pairs(global.tesseract_data) do
        i = i + 1
        entity.set_infinity_container_filter(i, {name=n, count=ss, mode='exactly', index=i})
    end
end

-- set the filters of all existing tesseract chests
local function update_all_chest_filters()
    for _,s in pairs(game.surfaces) do
        for _,e in pairs(s.find_entities_filtered{name=chest_names}) do
            update_chest_filters(e)
        end
    end
end

-- retrieve each item prototype and its stack size
local function update_tesseract_data()
    local include_hidden = settings.global['im-tesseract-include-hidden'].value
    local data = {}
    for n,p in pairs(game.item_prototypes) do
        if include_hidden or not p.has_flag('hidden') then
            data[n] = p.stack_size
        end
    end
    -- remove dummy-steel-axe, since trying to include it will crash the game
    data['dummy-steel-axe'] = nil
    global.tesseract_data = data
end

-- ----------------------------------------------------------------------------------------------------
-- LISTENERS

event.on_init(function(e)
    update_tesseract_data()
end)

event.on_configuration_changed(function(e)
    -- update filters of all tesseract chests
    update_tesseract_data()
    update_all_chest_filters() 
end)

-- when a mod setting changes
on_event(defines.events.on_runtime_mod_setting_changed, function(e)
    if e.setting == 'im-tesseract-include-hidden' then
        -- update filters of all tesseract chests
        update_tesseract_data()
        update_all_chest_filters()
    end
end)

-- when an entity is built
on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built}, function(e)
    local entity = e.created_entity or e.entity
    if entity.name:find('tesseract') then
        update_chest_filters(entity)
    end
end)