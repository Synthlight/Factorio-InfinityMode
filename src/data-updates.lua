-- add free crafting recipes for all ores
register_recipes({'wood'}, true)
for n,t in pairs(data.raw['resource']) do
    if t.minable then
        local results = {}
        if t.minable.result then
            results[1] = data.raw['item'][t.minable.result]
        elseif t.minable.results then
            for i,r in pairs(t.minable.results) do
                results[i] = data.raw['item'][r.name]
            end
        end
        for _,result in pairs(results) do
            local recipe = data.raw['recipe'][result.name]
            if result.type == 'item' and not recipe then
                result.subgroup = 'raw-resource'
                register_recipes({result.name}, true)
            end
        end
    end
end

-- INFINITY LOADER
local function is_sprite_def(array)
    return array.width and array.height and (array.filename or array.stripes or array.filenames)
end
local function recursive_tint(array, tint)
    tint = tint or infinity_tint
    for _,v in pairs (array) do
        if type(v) == "table" then
        if is_sprite_def(v) or v.icon then
            v.tint = tint
        end
        v = recursive_tint(v, tint)
        end
    end
    return array
end
local loader_base = table.deepcopy(data.raw['underground-belt']['underground-belt'])
loader_base.icons = {{icon='__InfinityMode__/graphics/item/infinity-loader.png', icon_size=32}}
for n,t in pairs(loader_base.structure) do
  if n ~= 'back_patch' and n ~= 'front_patch' then
    t.sheet.filename = '__InfinityMode__/graphics/entity/infinity-loader.png'
    t.sheet.hr_version.filename = '__InfinityMode__/graphics/entity/hr-infinity-loader.png'
  end
end
recursive_tint(loader_base)

local belt_patterns = {
  -- factorioextended plus transport: https://mods.factorio.com/mod/FactorioExtended-Plus-Transport
  ['%-?transport%-belt%-to%-ground'] = '',
  -- vanilla and 99% of mods
  ['%-?underground%-belt'] = ''
}

local function create_loader(base_underground)
  local entity = table.deepcopy(data.raw['underground-belt'][base_underground])
  -- adjust pictures and icon
  entity.structure = loader_base.structure
  entity.icons = loader_base.icons
  -- get name
  local suffix = entity.name
  for pattern, replacement in pairs(belt_patterns) do
    suffix = suffix:gsub(pattern, replacement)
  end
  entity.name = 'infinity-loader-loader' .. (suffix ~= '' and '-'..suffix or '')
  -- other data
  entity.type = 'loader'
  entity.next_upgrade = nil
  entity.max_distance = 0
  entity.order = 'a'
  entity.selectable_in_game = false
  entity.filter_count = 0
  entity.belt_distance = 0
  entity.belt_length = 0.6
  entity.container_distance = 0
  data:extend{entity}
end

for n,_ in pairs(table.deepcopy(data.raw['underground-belt'])) do
  create_loader(n)
end