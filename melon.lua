
--[[

Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

"crops" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

local faces = {
	[1] = { x = -1, z = 0, r = 3, o = 1, m = 14 },
	[2] = { x = 1, z = 0, r = 1, o = 3,  m = 16 },
	[3] = { x = 0, z = -1, r = 2, o = 0, m = 5  },
	[4] = { x = 0, z = 1, r = 0, o = 2,  m = 11 }
}

minetest.register_node("crops:melon_seed", {
	description = "melon seed",
	inventory_image = "crops_melon_seed.png",
	wield_image = "crops_melon_seed.png",
	tiles = { "crops_melon_plant_1.png" },
	drawtype = "plantlike",
	waving = 1,
	sunlight_propagates = false,
	use_texture_alpha = true,
	walkable = false,
	paramtype = "light",
	groups = { snappy=3,flammable=3,flora=1,attached_node=1 },

	on_place = function(itemstack, placer, pointed_thing)
		local under = minetest.get_node(pointed_thing.under)
		if minetest.get_item_group(under.name, "soil") <= 1 then
			return
		end
		crops.plant(pointed_thing.above, {name="crops:melon_plant_1"})
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end
})

for stage = 1, 6 do
minetest.register_node("crops:melon_plant_" .. stage , {
	description = "melon plant",
	tiles = { "crops_melon_plant_" .. stage .. ".png" },
	drawtype = "plantlike",
	waving = 1,
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	paramtype = "light",
	groups = { snappy=3, flammable=3, flora=1, attached_node=1, not_in_creative_inventory=1 },
	drop = "crops:melon_seed",
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5,  0.5, -0.5 + (((math.min(stage, 4)) + 1) / 5), 0.5}
	}
})
end

minetest.register_node("crops:melon_plant_5_attached", {
	visual = "mesh",
	mesh = "crops_plant_extra_face.obj",
	description = "melon plant",
	tiles = { "crops_melon_stem.png", "crops_melon_plant_4.png" },
	drawtype = "mesh",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	paramtype = "light",
	groups = { snappy=3, flammable=3, flora=1, attached_node=1, not_in_creative_inventory=1 },
	drop = "crops:melon_seed",
	sounds = default.node_sound_leaves_defaults(),
})


minetest.register_craftitem("crops:melon_slice", {
	description = "Melon slice",
	inventory_image = "crops_melon_slice.png",
	on_use = minetest.item_eat(1)
})

minetest.register_craft({
	type = "shapeless",
	output = "crops:melon_seed",
	recipe = { "crops:melon_slice" }
})

--
-- the melon "block"
--
minetest.register_node("crops:melon", {
	description = "Melon",
	inventory_image = "crops_melon_inv.png",
	tiles = { "crops_melon_top.png", "crops_melon_bottom.png", "crops_melon.png", "crops_melon.png", "crops_melon.png", "crops_melon.png" },
	sunlight_propagates = false,
	use_texture_alpha = false,
	walkable = true,
	groups = { snappy=3, flammable=3, oddly_breakable_by_hand=2 },
	paramtype2 = "facedir",
	drop = {max_items = 5, items = {
		{ items = {'crops:melon_slice'}, rarity = 1 },
		{ items = {'crops:melon_slice'}, rarity = 1 },
		{ items = {'crops:melon_slice'}, rarity = 1 },
		{ items = {'crops:melon_slice'}, rarity = 2 },
		{ items = {'crops:melon_slice'}, rarity = 5 },
	}},
	sounds = default.node_sound_wood_defaults({
		dig = { name = "default_dig_oddly_breakable_by_hand" },
		dug = { name = "default_dig_choppy" }
	}),
	on_dig = function(pos, node, digger)
		-- FIXME correct for damage
		local code = minetest.node_dig(pos, node, digger)
		for face = 1, 4 do
			local s = { x = pos.x + faces[face].x, y = pos.y, z = pos.z + faces[face].z }
			local n = minetest.get_node(s)
			if n.name == "crops:melon_plant_5_attached" then
				-- make sure it was actually attached to this stem
				if n.param2 == faces[face].o then
					minetest.swap_node(s, { name = "crops:melon_plant_4" })
					return code
				end
			end
		end
		return code
	end
})

--
-- grows a plant to mature size
--
minetest.register_abm({
	nodenames = { "crops:melon_plant_1", "crops:melon_plant_2", "crops:melon_plant_3","crops:melon_plant_4" },
	neighbors = { "group:soil" },
	interval = crops.interval,
	chance = crops.chance,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not crops.can_grow(pos) then
			return
		end
		local meta = minetest.get_meta(pos)
		local n = string.gsub(node.name, "4", "5")
		n = string.gsub(n, "3", "4")
		n = string.gsub(n, "2", "3")
		n = string.gsub(n, "1", "2")
		minetest.swap_node(pos, { name = n })
	end
})

--
-- grows a melon
--
minetest.register_abm({
	nodenames = { "crops:melon_plant_5" },
	neighbors = { "group:soil" },
	interval = crops.interval,
	chance = crops.chance,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not crops.can_grow(pos) then
			return
		end
		for face = 1, 4 do
			local t = { x = pos.x + faces[face].x, y = pos.y, z = pos.z + faces[face].z }
			if minetest.get_node(t).name == "crops:melon" then
				return
			end
		end
		local r = math.random(1, 4)
		local t = { x = pos.x + faces[r].x, y = pos.y, z = pos.z + faces[r].z }
		local n = minetest.get_node(t)
		if n.name == "ignore" then
			return
		end

		if minetest.registered_nodes[minetest.get_node({ x = t.x, y = t.y - 1, z = t.z }).name].walkable == false then
			return
		end

		if minetest.registered_nodes[n.name].drawtype == "plantlike" or
		   minetest.registered_nodes[n.name].groups.flora == 1 or
		   n.name == "air" then
			minetest.set_node(t, {name = "crops:melon", param2 = faces[r].m})
			minetest.swap_node(pos, {name = "crops:melon_plant_5_attached", param2 = faces[r].r})
		end
	end
})

--
-- return a melon to a normal one if there is no melon attached, so it can
-- grow a new melon again
--
minetest.register_abm({
	nodenames = { "crops:melon_plant_5_attached" },
	interval = crops.interval,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		for face = 1, 4 do
			local t = { x = pos.x + faces[face].x, y = pos.y, z = pos.z + faces[face].z }
			if minetest.get_node(t).name == "crops:melon" then
				return
			end
		end
		minetest.swap_node(pos, {name = "crops:melon_plant_4" })
	end
})

crops.melon_die = function(pos)
	minetest.set_node(pos, { name = "crops:melon_plant_6" })
end

local properties = {
	wither = crops.melon_die,
	waterstart = 20,
	wateruse = 1,
	night = 5,
	soak = 80,
	soak_damage = 90,
	wither = 20,
	wither_damage = 10,
}

table.insert(crops.plants, { name = "crops:melon_plant_1", properties = properties })
table.insert(crops.plants, { name = "crops:melon_plant_2", properties = properties })
table.insert(crops.plants, { name = "crops:melon_plant_3", properties = properties })
table.insert(crops.plants, { name = "crops:melon_plant_4", properties = properties })
table.insert(crops.plants, { name = "crops:melon_plant_5", properties = properties })
