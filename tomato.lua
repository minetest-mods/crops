
--[[

Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

"crops" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

local wateruse = 1

minetest.register_node("crops:tomato_seed", {
	description = "tomato seed",
	inventory_image = "crops_tomato_seed.png",
	wield_image = "crops_tomato_seed.png",
	tiles = { "crops_tomato_plant_1.png" },
	drawtype = "plantlike",
	waving = 1,
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	paramtype = "light",
	groups = { snappy=3,flammable=3,flora=1,attached_node=1 },
	drop = {},
	sounds = default.node_sound_leaves_defaults(),

	on_place = function(itemstack, placer, pointed_thing)
		local under = minetest.get_node(pointed_thing.under)
		if minetest.get_item_group(under.name, "soil") <= 1 then
			return
		end
		crops.plant(pointed_thing.above, {name="crops:tomato_plant_1"})
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end
})

for stage = 1, 4 do
minetest.register_node("crops:tomato_plant_" .. stage , {
	description = "tomato plant",
	tiles = { "crops_tomato_plant_" .. stage .. ".png" },
	drawtype = "plantlike",
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
		fixed = {-0.5, -0.5, -0.5,  0.5, -0.5 + (((math.min(stage, 4)) + 1) / 5), 0.5}
	}
})
end

minetest.register_node("crops:tomato_plant_5" , {
	description = "tomato plant",
	tiles = { "crops_tomato_plant_5.png" },
	drawtype = "plantlike",
	waving = 1,
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	paramtype = "light",
	groups = { snappy=3, flammable=3, flora=1, attached_node=1, not_in_creative_inventory=1 },
	drop = {},
	sounds = default.node_sound_leaves_defaults(),
	on_dig = function(pos, node, digger)
		local drops = {}
		for i = 1, math.random(1, 2) do
			table.insert(drops, "crops:tomato")
		end
		core.handle_node_drops(pos, drops, digger)

		local meta = minetest.get_meta(pos)
		local ttl = meta:get_int("crops_tomato_ttl")
		local water = meta:get_int("crops_water")
		local damage = meta:get_int("crops_damage")
		if ttl > 1 then
			minetest.set_node(pos, { name = "crops:tomato_plant_4"})
			meta:set_int("crops_tomato_ttl", ttl - 1)
		else
			minetest.set_node(pos, { name = "crops:tomato_plant_6"})
			meta:set_int("crops_tomato_ttl", 0)
		end
		meta:set_int("crops_water", water)
		meta:set_int("crops_damage", damage)
	end
})

minetest.register_node("crops:tomato_plant_6", {
	description = "tomato plant",
	tiles = { "crops_tomato_plant_6.png" },
	drawtype = "plantlike",
	waving = 1,
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	paramtype = "light",
	groups = { snappy=3, flammable=3, flora=1, attached_node=1, not_in_creative_inventory=1 },
	drop = {},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_craftitem("crops:tomato", {
	description = "Tomato",
	inventory_image = "crops_tomato.png",
	on_use = minetest.item_eat(1)
})

minetest.register_craft({
	type = "shapeless",
	output = "crops:tomato_seed",
	recipe = { "crops:tomato" }
})

--
-- grows a plant to mature size
--
minetest.register_abm({
	nodenames = { "crops:tomato_plant_1", "crops:tomato_plant_2", "crops:tomato_plant_3" },
	neighbors = { "group:soil" },
	interval = crops.interval,
	chance = crops.chance,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not crops.can_grow(pos) then
			return
		end
		local meta = minetest.get_meta(pos)
		local water = meta:get_int("crops_water")
		local damage = meta:get_int("crops_damage")
		local n = string.gsub(node.name, "4", "5")
		n = string.gsub(n, "3", "4")
		n = string.gsub(n, "2", "3")
		n = string.gsub(n, "1", "2")
		minetest.set_node(pos, { name = n })
		meta:set_int("crops_water", water)
		meta:set_int("crops_damage", damage)
	end
})

--
-- grows a tomato
--
minetest.register_abm({
	nodenames = { "crops:tomato_plant_4" },
	neighbors = { "group:soil" },
	interval = crops.interval,
	chance = crops.chance,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not crops.can_grow(pos) then
			return
		end
		local meta = minetest.get_meta(pos)
		local ttl = meta:get_int("crops_tomato_ttl")
		local water = meta:get_int("crops_water")
		local damage = meta:get_int("crops_damage")
		if ttl == 0 then
			-- damage 0   - drops 4-6
			-- damage 50  - drops 2-3
			-- damage 100 - drops 0-1
			ttl = math.random(4 - (4 * (damage / 100)), 6 - (5 * (damage / 100)))
		end
		if ttl > 1 then
			minetest.set_node(pos, { name = "crops:tomato_plant_5" })
			meta:set_int("crops_tomato_ttl", ttl)
			meta:set_int("crops_water", water)
			meta:set_int("crops_damage", damage)
		else
			-- no luck, plant dead!
			minetest.set_node(pos, { name = "crops:tomato_plant_6" })
		end
	end
})

crops.tomato_die = function(pos)
	minetest.set_node(pos, { name = "crops:tomato_plant_6" })
end

table.insert(crops.plants, { name = "crops:tomato_plant_1", wateruse = 1.0, wither = crops.tomato_die })
table.insert(crops.plants, { name = "crops:tomato_plant_2", wateruse = 1.0, wither = crops.tomato_die })
table.insert(crops.plants, { name = "crops:tomato_plant_3", wateruse = 1.0, wither = crops.tomato_die })
table.insert(crops.plants, { name = "crops:tomato_plant_4", wateruse = 1.0, wither = crops.tomato_die })
table.insert(crops.plants, { name = "crops:tomato_plant_5", wateruse = 1.0, wither = crops.tomato_die })

