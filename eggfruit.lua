
--[[

Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>
              2018 - Marius Spix <marius.spix@web.de>

"crops" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

-- Intllib
local S = crops.intllib

minetest.register_node("crops:eggfruit_seed", {
	description = S("Eggfruit seed"),
	inventory_image = "crops_eggfruit_seed.png",
	wield_image = "crops_eggfruit_seed.png",
	tiles = { "crops_eggfruit_plant_1.png" },
	drawtype = "plantlike",
	paramtype2 = "meshoptions",
	waving = 1,
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	paramtype = "light",
	node_placement_prediction = "crops:eggfruit_plant_1",
	groups = { snappy=3,flammable=3,flora=1,attached_node=1 },
	drop = {},
	sounds = default.node_sound_leaves_defaults(),

	on_place = function(itemstack, placer, pointed_thing)
		local under = minetest.get_node(pointed_thing.under)
		if minetest.get_item_group(under.name, "soil") <= 1 then
			return
		end
		crops.plant(pointed_thing.above, {name="crops:eggfruit_plant_1", param2 = 1})
		if not minetest.settings:get_bool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end
})

for stage = 1, 7 do
	local node_def =
	{
		description = S("Eggfruit plant"),
		tiles = { "crops_eggfruit_plant_" .. stage .. ".png" },
		drawtype = "plantlike",
		paramtype2 = "meshoptions",
		waving = 1,
		sunlight_propagates = true,
		use_texture_alpha = true,
		walkable = false,
		paramtype = "light",
		groups = { snappy=3, flammable=3, flora=1, attached_node=1, not_in_creative_inventory=1 },
		drop = {},
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = {-0.45, -0.5, -0.45,  0.45, -0.6 + (((math.min(stage, 5)) + 1) / 6), 0.45}
		}
	}

	if stage == 6 then
		node_def.on_dig = function(pos, node, digger)
			local drops = {}
			for i = 1, math.random(1, 2) do
				table.insert(drops, "crops:eggfruit")
			end
			core.handle_node_drops(pos, drops, digger)

			local meta = minetest.get_meta(pos)
			local ttl = meta:get_int("crops_eggfruit_ttl")
			if ttl > 1 then
				minetest.swap_node(pos, { name = "crops:eggfruit_plant_4", param2 = 1})
				meta:set_int("crops_eggfruit_ttl", ttl - 1)
			else
				crops.die(pos)
			end
		end
	end
	
	minetest.register_node("crops:eggfruit_plant_" .. stage , node_def)
end

minetest.register_craftitem("crops:eggfruit", {
	description = S("Eggfruit"),
	inventory_image = "crops_eggfruit.png",
	on_use = minetest.item_eat(1)
})

minetest.register_craft({
	type = "shapeless",
	output = "crops:eggfruit_seed",
	recipe = { "crops:eggfruit" }
})

--
-- grows a plant to mature size
--
minetest.register_abm({
	nodenames = { "crops:eggfruit_plant_1", "crops:eggfruit_plant_2", "crops:eggfruit_plant_3",
	              "crops:eggfruit_plant_4" },
	neighbors = { "group:soil" },
	interval = crops.settings.interval,
	chance = crops.settings.chance,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not crops.can_grow(pos) then
			return
		end
		local n = string.gsub(node.name, "5", "6")
		n = string.gsub(n, "4", "5")
		n = string.gsub(n, "3", "4")
		n = string.gsub(n, "2", "3")
		n = string.gsub(n, "1", "2")
		minetest.swap_node(pos, { name = n, param2 = 1 })
	end
})

--
-- grows an eggfruit
--
minetest.register_abm({
	nodenames = { "crops:eggfruit_plant_5" },
	neighbors = { "group:soil" },
	interval = crops.settings.interval,
	chance = crops.settings.chance,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not crops.can_grow(pos) then
			return
		end
		local meta = minetest.get_meta(pos)
		local ttl = meta:get_int("crops_eggfruit_ttl")
		local damage = meta:get_int("crops_damage")
		if ttl == 0 then
			-- damage 0   - drops 4-5
			-- damage 50  - drops 2-3
			-- damage 100 - drops 0-1
			ttl = math.random(4 - (4 * (damage / 100)), 5 - (4 * (damage / 100)))
		end
		if ttl > 1 then
			minetest.swap_node(pos, { name = "crops:eggfruit_plant_6", param2 = 1 })
			meta:set_int("crops_eggfruit_ttl", ttl)
		else
			crops.die(pos)
		end
	end
})

crops.eggfruit_die = function(pos)
	minetest.swap_node(pos, { name = "crops:eggfruit_plant_7", param2 = 1 })
end

local properties = {
	die = crops.eggfruit_die,
	waterstart = 20,
	wateruse = 1,
	night = 5,
	soak = 84,
	soak_damage = 70,
	wither = 15,
	wither_damage = 10,
}

for stage = 1, 6 do
	crops.register({ name = "crops:eggfruit_plant_" .. stage, properties = properties })
end
