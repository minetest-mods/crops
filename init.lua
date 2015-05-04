
--[[

Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

"crops" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

crops = {}
crops.plants = {}

local worldpath = minetest.get_worldpath()
local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath .. "/crops_settings.txt")

if io.open(worldpath .. "/crops_settings.txt", "r") == nil then
	io.input(modpath .. "/crops_settings.txt")
	io.output(worldpath .. "/crops_settings.txt")

	local size = 4096
	while true do
		local buf = io.read(size)
		if not buf then
			io.close()
			break
		end
		io.write(buf)
	end
else
	dofile(worldpath .. "/crops_settings.txt")
end

local find_plant = function(node)
	for i = 1,table.getn(crops.plants) do
		if crops.plants[i].name == node.name then
			return crops.plants[i]
		end
	end
	minetest.log("error", "Unable to find plant \"" .. node.name .. "\" in crops table")
	return nil
end

crops.plant = function(pos, node)
	minetest.set_node(pos, node)
	local meta = minetest.get_meta(pos)
	local plant = find_plant(node)
	meta:set_int("crops_water", plant.properties.waterstart)
	meta:set_int("crops_damage", 0)
end

crops.can_grow = function(pos)
	if minetest.get_node_light(pos, nil) < crops.light then
		return false
	end
	local node = minetest.get_node(pos)
	local plant = find_plant(node)
	if not plant then
		return false
	end
	local meta = minetest.get_meta(pos)
	local water = meta:get_int("crops_water")
	if water < plant.properties.wither or water > plant.properties.soak then
		if math.random(0,1) == 0 then
			return false
		end
	end
	local damage = meta:get_int("crops_damage")
	if not damage == 0 then
		if math.random(math.min(50, damage), 100) > 75 then
			return false
		end
	end

	-- allow the plant to grow
	return true
end

crops.particles = function(pos, flag)
	local p = {}
	if flag == 0 then
		-- wither (0)
		p = {
			amount = 1 * crops.interval,
			time = crops.interval,
			minpos = { x = pos.x - 0.4, y = pos.y - 0.4, z = pos.z - 0.4 },
			maxpos = { x = pos.x + 0.4, y = pos.y + 0.4, z = pos.z + 0.4 },
			minvel = { x = 0, y = 0.2, z = 0 },
			maxvel = { x = 0, y = 0.4, z = 0 },
			minacc = { x = 0, y = 0, z = 0 },
			maxacc = { x = 0, y = 0.2, z = 0 },
			minexptime = 3,
			maxexptime = 5,
			minsize = 1,
			maxsize = 2,
			collisiondetection = false,
			texture = "crops_wither.png",
			vertical = true,
		}
	else
		-- soak (1)
		p = {
			amount = 8 * crops.interval,
			time = crops.interval,
			minpos = { x = pos.x - 0.4, y = pos.y - 0.4, z = pos.z - 0.4 },
			maxpos = { x = pos.x + 0.4, y = pos.y - 0.4, z = pos.z + 0.4 },
			minvel = { x = -0.04, y = 0, z = -0.04 },
			maxvel = { x = 0.04, y = 0, z = 0.04 },
			minacc = { x = 0, y = 0, z = 0 },
			maxacc = { x = 0, y = 0, z = 0 },
			minexptime = 3,
			maxexptime = 5,
			minsize = 1,
			maxsize = 2,
			collisiondetection = false,
			texture = "crops_soak.png",
			vertical = false,
		}
	end
	minetest.add_particlespawner(p)
end

minetest.register_tool("crops:watering_can", {
	description = "Watering Can",
	inventory_image = "crops_watering_can.png",
	liquids_pointable = true,
	range = 2.5,
	stack_max = 1,
	wear = 65535,
	tool_capabilities = {},
	on_use = function(itemstack, user, pointed_thing)
		local pos = pointed_thing.under
		if pos == nil then
			return itemstack
		end
		-- filling it up?
		local node = minetest.get_node(pos)
		if node.name == "default:water_source" or
		   node.name == "default:water_flowing" then
			itemstack:set_wear(1)
			return itemstack
		end
		-- using it on a plant?
		local meta = minetest.get_meta(pos)
		local water = meta:get_int("crops_water")
		if water == nil then
			return itemstack
		end
		local wear = itemstack:get_wear()
		-- empty?
		if wear == 65534 then
			return itemstack
		end
		water = math.min(water + crops.watercan, crops.watercan_max)
		meta:set_int("crops_water", water)
		itemstack:set_wear(math.min(65534, wear + (65535 / crops.watercanuses)))
		return itemstack
	end,
})

minetest.register_tool("crops:hydrometer", {
	description = "Hydrometer",
	inventory_image = "crops_hydrometer.png",
	liquids_pointable = false,
	range = 2.5,
	stack_max = 1,
	tool_capabilities = {
	},
	on_use = function(itemstack, user, pointed_thing)
		local pos = pointed_thing.under
		if pos == nil then
			return itemstack
		end
		local meta = minetest.get_meta(pos)
		-- using it on a plant?
		local water = meta:get_int("crops_water")
		if water == nil then
			itemstack:set_wear(65534)
			return itemstack
		end
		itemstack:set_wear(65535 - ((65534 / 100) * water))
		return itemstack
	end,
})

minetest.register_craft({
	output = "crops:watering_can",
	recipe = {
		{ "default:steel_ingot", "", "" },
		{ "default:steel_ingot", "", "default:steel_ingot" },
		{ "", "default:steel_ingot", "" },
	},
})

minetest.register_craft({
	output = "crops:hydrometer",
	recipe = {
		{ "default:mese_crystal_fragment", "", "" },
		{ "", "default:steel_ingot", "" },
		{ "", "", "default:steel_ingot" },
	},
})

-- crop nodes, crafts, craftitems
dofile(modpath .. "/melon.lua")
dofile(modpath .. "/corn.lua")
dofile(modpath .. "/tomato.lua")
dofile(modpath .. "/potato.lua")
dofile(modpath .. "/polebean.lua")

-- water handling code
minetest.register_abm({
	nodenames = {
		"crops:tomato_plant_1", "crops:tomato_plant_2", "crops:tomato_plant_3", "crops:tomato_plant_4", "crops:tomato_plant_5",
		"crops:potato_plant_1", "crops:potato_plant_2", "crops:potato_plant_3", "crops:potato_plant_4",
		"crops:melon_plant_1", "crops:melon_plant_2", "crops:melon_plant_3", "crops:melon_plant_4", "crops:melon_plant_5"
	},
	interval = crops.interval,
	chance = crops.chance,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local water = meta:get_int("crops_water")
		local damage = meta:get_int("crops_damage")

		-- get plant specific data
		local plant = find_plant(node)
		if plant == nil then
			return
		end

		-- increase water for nearby water sources
		local f = minetest.find_node_near(pos, 1, {"default:water_source", "default:water_flowing"})
		if not f == nil then
			water = math.min(100, water + 2)
		else
			local f = minetest.find_node_near(pos, 2, {"default:water_source", "default:water_flowing"})
			if not f == nil then
				water = math.min(100, water + 1)
			end
		end

		-- compensate for light: at night give some water back to the plant
		if minetest.get_node_light(pos, nil) < plant.properties.night then
			water = math.min(100, water + 1)
		end

		-- dry out the plant
		water = math.max(0, water - plant.properties.wateruse )
		meta:set_int("crops_water", water)
		if water < plant.properties.wither_damage then
			crops.particles(pos, 0)
			damage = damage + math.random(0,5)
		elseif water < plant.properties.wither then
			crops.particles(pos, 0)
			return
		elseif water > plant.properties.soak_damage then
			crops.particles(pos, 1)
			damage = damage + math.random(0,5)
		elseif water > plant.properties.soak then
			crops.particles(pos, 1)
			return
		end
		meta:set_int("crops_damage", math.min(crops.max_damage, damage))

		-- is it dead?
		if damage >= 100 then
			plant.properties.wither(pos)
		end
	end
})

-- cooking recipes that mix craftitems
dofile(modpath .. "/cooking.lua")

minetest.log("action", "[crops] loaded.")
