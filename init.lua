
--[[

Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

"crops" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

crops = {}
crops.plants = {}
crops.settings = {}

local settings = {}
settings.easy = {
	chance = 4,
	interval = 30,
	light = 8,
	watercan = 25,
	watercan_max = 90,
	watercan_uses = 20,
	damage_chance = 8,
	damage_interval = 30,
	damage_tick_min = 0,
	damage_tick_max = 1,
	damage_max = 25,
}
settings.normal = {
	chance = 8,
	interval = 30,
	light = 10,
	watercan = 25,
	watercan_max = 90,
	watercan_uses = 20,
	damage_chance = 8,
	damage_interval = 30,
	damage_tick_min = 0,
	damage_tick_max = 5,
	damage_max = 50,
}
settings.difficult = {
	chance = 16,
	interval = 30,
	light = 13,
	watercan = 25,
	watercan_max = 100,
	watercan_uses = 20,
	damage_chance = 4,
	damage_interval = 30,
	damage_tick_min = 3,
	damage_tick_max = 7,
	damage_max = 100,
}

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

if not crops.difficulty then
	crops.difficulty = "normal"
	minetest.log("error", "Defaulting to \"normal\" difficulty settings")
end
crops.settings = settings[crops.difficulty]
if not crops.settings then
	minetest.log("error", "Defaulting to \"normal\" difficulty settings")
	crops.settings = settings.normal
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

crops.register = function(plantdef)
	table.insert(crops.plants, plantdef)
end

crops.plant = function(pos, node)
	minetest.set_node(pos, node)
	local meta = minetest.get_meta(pos)
	local plant = find_plant(node)
	meta:set_int("crops_water", plant.properties.waterstart)
	meta:set_int("crops_damage", 0)
end

crops.can_grow = function(pos)
	if minetest.get_node_light(pos) < crops.settings.light then
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
	-- growing costs water!
	meta:set_int("crops_water", math.max(0, water - 10))

	-- allow the plant to grow
	return true
end

crops.particles = function(pos, flag)
	local p = {}
	if flag == 0 then
		-- wither (0)
		p = {
			amount = 1 * crops.settings.interval,
			time = crops.settings.interval,
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
	elseif flag == 1 then
		-- soak (1)
		p = {
			amount = 8 * crops.settings.interval,
			time = crops.settings.interval,
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
	else -- watering (2)
		p = {
			amount = 30,
			time = 3,
			minpos = { x = pos.x - 0.4, y = pos.y - 0.4, z = pos.z - 0.4 },
			maxpos = { x = pos.x + 0.4, y = pos.y + 0.4, z = pos.z + 0.4 },
			minvel = { x = 0, y = 0.0, z = 0 },
			maxvel = { x = 0, y = 0.0, z = 0 },
			minacc = { x = 0, y = -9.81, z = 0 },
			maxacc = { x = 0, y = -9.81, z = 0 },
			minexptime = 2,
			maxexptime = 2,
			minsize = 1,
			maxsize = 3,
			collisiondetection = false,
			texture = "crops_watering.png",
			vertical = true,
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
		local ppos = pos
		if not pos then
			return itemstack
		end
		-- filling it up?
		local wear = itemstack:get_wear()
		if minetest.get_item_group(minetest.get_node(pos).name, "water") >= 3 then
			if wear ~= 1 then
				minetest.sound_play("crops_watercan_entering", {pos=pos, gain=0.8})
				minetest.after(math.random()/2, function(pos)
					if math.random(2) == 1 then
						minetest.sound_play("crops_watercan_splash_quiet", {pos=pos, gain=0.1})
					end
					if math.random(3) == 1 then
						minetest.after(math.random()/2, function(pos)
							minetest.sound_play("crops_watercan_splash_small", {pos=pos, gain=0.7})
						end, pos)
					end
					if math.random(3) == 1 then
						minetest.after(math.random()/2, function(pos)
							minetest.sound_play("crops_watercan_splash_big", {pos=pos, gain=0.7})
						end, pos)
					end
				end, pos)
				itemstack:set_wear(1)
			end
			return itemstack
		end
		-- using it on a top-half part of a plant?
		local meta = minetest.get_meta(pos)
		if meta:get_int("crops_top_half") == 1 then
			meta = minetest.get_meta({x=pos.x, y=pos.y-1, z=pos.z})
		end
		-- using it on a plant?
		local water = meta:get_int("crops_water")
		if water == nil then
			return itemstack
		end
		-- empty?
		if wear == 65534 then
			return itemstack
		end
		crops.particles(ppos, 2)
		water = math.min(water + crops.settings.watercan, crops.settings.watercan_max)
		meta:set_int("crops_water", water)

		itemstack:set_wear(math.min(65534, wear + (65535 / crops.settings.watercan_uses)))
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
		if not pos then
			return itemstack
		end
		-- doublesize plant?
		local meta = minetest.get_meta(pos)
		if meta:get_int("crops_top_half") == 1 then
			meta = minetest.get_meta({x=pos.x, y=pos.y-1, z=pos.z})
		end

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

local nodenames = {}
for i = 1,table.getn(crops.plants) do
	table.insert(nodenames, crops.plants[i].name)
end

-- water handling code
minetest.register_abm({
	nodenames = nodenames,
	interval = crops.settings.damage_interval,
	chance = crops.settings.damage_chance,
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

		if minetest.get_node_light(pos, nil) < plant.properties.night then
			-- compensate for light: at night give some water back to the plant
			water = math.min(100, water + 1)
		else
			-- dry out the plant
			water = math.max(0, water - plant.properties.wateruse )
		end

		meta:set_int("crops_water", water)

		-- for convenience, copy water attribute to top half
		if not plant.properties.doublesize == nil and plant.properties.doublesize then
			local above = { x = pos.x, y = pos.y + 1, z = pos.z}
			local meta = minetest.get_meta(above)
			meta:set_int("crops_water", water)
		end

		if water <= plant.properties.wither_damage then
			crops.particles(pos, 0)
			damage = damage + math.random(crops.settings.damage_tick_min, crops.settings.damage_tick_max)
		elseif water <= plant.properties.wither then
			crops.particles(pos, 0)
			return
		elseif water >= plant.properties.soak_damage then
			crops.particles(pos, 1)
			damage = damage + math.random(crops.settings.damage_tick_min, crops.settings.damage_tick_max)
		elseif water >= plant.properties.soak then
			crops.particles(pos, 1)
			return
		end
		meta:set_int("crops_damage", math.min(crops.settings.damage_max, damage))

		-- is it dead?
		if damage >= 100 then
			plant.properties.die(pos)
		end
	end
})

-- cooking recipes that mix craftitems
dofile(modpath .. "/cooking.lua")

minetest.log("action", "[crops] loaded.")
