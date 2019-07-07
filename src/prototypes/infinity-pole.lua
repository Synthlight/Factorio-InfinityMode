-- ------------------------------------------------------------------------------------------
-- ITEMS

local ip_item = table.deepcopy(data.raw['item']['big-electric-pole'])
ip_item.name = 'infinity-electric-pole'
ip_item.icons = { {icon=ip_item.icon, tint=infinity_tint} }
ip_item.place_result = 'infinity-electric-pole'
ip_item.subgroup = 'im-electricity'
ip_item.order = 'ba'

local is_item = table.deepcopy(data.raw['item']['substation'])
is_item.name = 'infinity-substation'
is_item.icons = { {icon=is_item.icon, tint=infinity_tint} }
is_item.place_result = 'infinity-substation'
is_item.subgroup = 'im-electricity'
is_item.order = 'bb'

data:extend{ip_item, is_item}

-- ------------------------------------------------------------------------------------------
-- ENTITIES

local ip_entity = table.deepcopy(data.raw['electric-pole']['big-electric-pole'])
ip_entity.name = 'infinity-electric-pole'
ip_entity.icons = { {icon=ip_item.icon, tint=infinity_tint} }
ip_entity.subgroup = 'im-electricity'
ip_entity.order = 'ba'
ip_entity.minable.result = 'infinity-electric-pole'
for _,t in pairs(ip_entity.pictures.layers) do
    t.tint = infinity_tint
    t.hr_version.tint = infinity_tint
end
ip_entity.maximum_wire_distance = 64

local is_entity = table.deepcopy(data.raw['electric-pole']['substation'])
is_entity.name = 'infinity-substation'
is_entity.icons = { {icon=is_item.icon, tint=infinity_tint} }
is_entity.subgroup = 'im-electricity'
is_entity.order = 'bb'
is_entity.minable.result = 'infinity-substation'
for _,t in pairs(is_entity.pictures.layers) do
    t.tint = infinity_tint
    t.hr_version.tint = infinity_tint
end
is_entity.maximum_wire_distance = 64
is_entity.supply_area_distance = 64

data:extend{ip_entity, is_entity}

-- ------------------------------------------------------------------------------------------
-- RECIPES

register_recipes{'infinity-electric-pole', 'infinity-substation'}