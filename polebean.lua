--[[

Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

"crops" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

-- Intllib
local S = crops.intllib
local ALPHA_CLIP = core.features.use_texture_alpha_string_modes and "clip" or true

core.register_craft({
	output = "crops:beanpoles",
	recipe = {
		{ "", "", "" },
		{ "default:stick", "", "default:stick" },
		{ "default:stick", "", "default:stick" },
	},
})

core.register_craftitem("crops:green_bean", {
	description = S("Green Bean"),
	inventory_image = "crops_green_bean.png",
	on_use = core.item_eat(1),
})

core.register_craft({
	type = "shapeless",
	output = "crops:green_bean_seed",
	recipe = { "crops:green_bean" },
})

local function crops_beanpole_on_dig(pos, node, digger)
	local bottom
	local bottom_n
	local top
	local top_n
	local drops = {}

	if
		node.name == "crops:beanpole_base"
		or node.name == "crops:beanpole_plant_base_1"
		or node.name == "crops:beanpole_plant_base_2"
		or node.name == "crops:beanpole_plant_base_3" --grown tall enough for top section
		or node.name == "crops:beanpole_plant_base_4" --flowering
		or node.name == "crops:beanpole_plant_base_5" --ripe
		or node.name == "crops:beanpole_plant_base_6" --harvested
	then
		bottom = pos
		bottom_n = node
		top = { x = pos.x, y = pos.y + 1, z = pos.z }
		top_n = core.get_node(top)
	elseif
		node.name == "crops:beanpole_top"
		or node.name == "crops:beanpole_plant_top_1"
		or node.name == "crops:beanpole_plant_top_2" --flowering
		or node.name == "crops:beanpole_plant_top_3" --ripe
		or node.name == "crops:beanpole_plant_top_4" --harvested
	then
		top = pos
		top_n = node
		bottom = { x = pos.x, y = pos.y - 1, z = pos.z }
		bottom_n = core.get_node(bottom)
	else
		-- ouch, this shouldn't happen
		print("beanpole on_dig falsely attached to: " .. pos.x .. "," .. pos.y .. "," .. pos.z)
		return
	end

	if bottom_n.name == "crops:beanpole_base" and top_n.name == "crops:beanpole_top" then
		-- bare beanpole
		table.insert(drops, "crops:beanpoles")
		core.remove_node(bottom)
		core.remove_node(top)
	elseif
		(
			bottom_n.name == "crops:beanpole_plant_base_1"
			or bottom_n.name == "crops:beanpole_plant_base_2"
			or bottom_n.name == "crops:beanpole_plant_base_3"
			or bottom_n.name == "crops:beanpole_plant_base_4"
		)
		and (
			top_n.name == "crops:beanpole_top"
			or top_n.name == "crops:beanpole_plant_top_1"
			or top_n.name == "crops:beanpole_plant_top_2"
		)
	then
		-- non-ripe
		for i = 1, 4 do
			table.insert(drops, "default:stick")
		end
		core.set_node(bottom, { name = "crops:beanpole_base" })
		core.set_node(top, { name = "crops:beanpole_top" })
	elseif bottom_n.name == "crops:beanpole_plant_base_5" and top_n.name == "crops:beanpole_plant_top_3" then
		-- ripe beanpole
		local meta = core.get_meta(bottom)
		local damage = meta:get_int("crops_damage")
		--   0 - 3-7
		--  50 - 2-4
		-- 100 - 1-1
		for i = 1, math.random(3 - (2 * (damage / 100)), 7 - (6 * (damage / 100))) do
			table.insert(drops, "crops:green_bean")
		end
		crops.die(bottom)
	elseif bottom_n.name == "crops:beanpole_plant_base_6" and top_n.name == "crops:beanpole_plant_top_4" then
		-- harvested beans
		for i = 1, math.random(3, 4) do
			table.insert(drops, "default:stick")
		end
		core.remove_node(bottom)
		core.remove_node(top)
	else
		-- ouch, this shouldn't happen
		print(
			"beanpole on_dig can't handle blocks at to: "
				.. bottom.x
				.. ","
				.. bottom.y
				.. ","
				.. bottom.z
				.. " and "
				.. top.x
				.. ","
				.. top.y
				.. ","
				.. top.z
		)
		print("removing a " .. node.name .. " at " .. pos.x .. "," .. pos.y .. "," .. pos.z)
		core.remove_node(pos)
		return
	end

	core.handle_node_drops(pos, drops, digger)
end

core.register_node("crops:beanpole_base", {
	description = "",
	drawtype = "plantlike",
	tiles = { "crops_beanpole_base.png" },
	use_texture_alpha = ALPHA_CLIP,
	walkable = true,
	sunlight_propagates = true,
	paramtype = "light",
	groups = { snappy = 3, flammable = 3, flora = 1, attached_node = 1, not_in_creative_inventory = 1 },
	drop = {},
	sounds = default.node_sound_leaves_defaults(),
	on_dig = crops_beanpole_on_dig,
})

core.register_node("crops:beanpole_top", {
	description = "",
	drawtype = "plantlike",
	tiles = { "crops_beanpole_top.png" },
	use_texture_alpha = ALPHA_CLIP,
	walkable = true,
	sunlight_propagates = true,
	paramtype = "light",
	groups = { snappy = 3, flammable = 3, flora = 1, not_in_creative_inventory = 1 },
	drop = {},
	sounds = default.node_sound_leaves_defaults(),
	on_dig = crops_beanpole_on_dig,
})

core.register_node("crops:beanpoles", {
	description = S("Beanpoles"),
	inventory_image = "crops_beanpole_top.png",
	wield_image = "crops_beanpole_top.png",
	tiles = { "crops_beanpole_base.png" },
	drawtype = "plantlike",
	sunlight_propagates = true,
	use_texture_alpha = ALPHA_CLIP,
	paramtype = "light",
	groups = { snappy = 3, flammable = 3, flora = 1, attached_node = 1 },
	drop = {},
	sounds = default.node_sound_leaves_defaults(),
	node_placement_prediction = "crops:beanpole_base",

	on_place = function(itemstack, placer, pointed_thing)
		local under = core.get_node(pointed_thing.under)
		if core.get_item_group(under.name, "soil") <= 1 then
			return
		end
		local top = { x = pointed_thing.above.x, y = pointed_thing.above.y + 1, z = pointed_thing.above.z }
		if core.get_node(top).name ~= "air" then
			return
		end
		core.set_node(pointed_thing.above, { name = "crops:beanpole_base" })
		core.set_node(top, { name = "crops:beanpole_top" })
		if not core.settings:get_bool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})

core.register_craftitem("crops:green_bean_seed", {
	description = S("Green bean seed"),
	inventory_image = "crops_green_bean_seed.png",
	wield_image = "crops_green_bean_seed.png",
	node_placement_prediction = "", -- disabled, prediction assumes pointed_think.above!

	on_place = function(itemstack, placer, pointed_thing)
		local under = core.get_node(pointed_thing.under)
		if under.name == "crops:beanpole_base" then
			crops.plant(pointed_thing.under, { name = "crops:beanpole_plant_base_1" })
			local above = { x = pointed_thing.under.x, y = pointed_thing.under.y + 1, z = pointed_thing.under.z }
			local meta = core.get_meta(above)
			meta:set_int("crops_top_half", 1)
		elseif under.name == "crops:beanpole_top" then
			local below = { x = pointed_thing.under.x, y = pointed_thing.under.y - 1, z = pointed_thing.under.z }
			if core.get_node(below).name == "crops:beanpole_base" then
				crops.plant(below, { name = "crops:beanpole_plant_base_1" })
				local meta = core.get_meta(pointed_thing.under)
				meta:set_int("crops_top_half", 1)
			else
				return
			end
		else
			return
		end
		if not core.settings:get_bool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})

for stage = 1, 6 do
	core.register_node("crops:beanpole_plant_base_" .. stage, {
		description = S("Green Bean plant"),
		tiles = { "crops_beanpole_plant_base_" .. stage .. ".png" },
		drawtype = "plantlike",
		sunlight_propagates = true,
		use_texture_alpha = ALPHA_CLIP,
		paramtype = "light",
		walkable = false,
		groups = { snappy = 3, flammable = 3, flora = 1, attached_node = 1, not_in_creative_inventory = 1 },
		drop = {},
		sounds = default.node_sound_leaves_defaults(),
		on_dig = crops_beanpole_on_dig,
	})
end

for stage = 1, 4 do
	core.register_node("crops:beanpole_plant_top_" .. stage, {
		description = S("Green Bean plant"),
		tiles = { "crops_beanpole_plant_top_" .. stage .. ".png" },
		drawtype = "plantlike",
		sunlight_propagates = true,
		use_texture_alpha = ALPHA_CLIP,
		paramtype = "light",
		walkable = true,
		groups = { snappy = 3, flammable = 3, flora = 1, not_in_creative_inventory = 1 },
		drop = {},
		sounds = default.node_sound_leaves_defaults(),
		on_dig = crops_beanpole_on_dig,
	})
end

core.register_abm({
	nodenames = {
		"crops:beanpole_plant_base_1",
		"crops:beanpole_plant_base_2",
		"crops:beanpole_plant_base_3",
		"crops:beanpole_plant_base_4",
	},
	interval = crops.settings.interval,
	chance = crops.settings.chance,
	neighbors = { "group:soil" },
	action = function(pos, node, active_object_count, active_object_count_wider)
		if not crops.can_grow(pos) then
			return
		end
		if node.name == "crops:beanpole_plant_base_1" then
			core.swap_node(pos, { name = "crops:beanpole_plant_base_2" })
		elseif node.name == "crops:beanpole_plant_base_2" then
			core.swap_node(pos, { name = "crops:beanpole_plant_base_3" })
		elseif node.name == "crops:beanpole_plant_base_3" then
			local apos = { x = pos.x, y = pos.y + 1, z = pos.z }
			local above = core.get_node(apos)
			if above.name == "crops:beanpole_top" then
				core.set_node(apos, { name = "crops:beanpole_plant_top_1" })
				local meta = core.get_meta(apos)
				meta:set_int("crops_top_half", 1)
			elseif above.name == "crops:beanpole_plant_top_1" then
				core.swap_node(pos, { name = "crops:beanpole_plant_base_4" })
				core.swap_node(apos, { name = "crops:beanpole_plant_top_2" })
			end
		elseif node.name == "crops:beanpole_plant_base_4" then
			local apos = { x = pos.x, y = pos.y + 1, z = pos.z }
			core.swap_node(pos, { name = "crops:beanpole_plant_base_5" })
			core.swap_node(apos, { name = "crops:beanpole_plant_top_3" })
		end
	end,
})

crops.beanpole_die = function(pos)
	core.set_node(pos, { name = "crops:beanpole_plant_base_6" })
	local above = { x = pos.x, y = pos.y + 1, z = pos.z }
	core.set_node(above, { name = "crops:beanpole_plant_top_4" })
end

local properties = {
	die = crops.beanpole_die,
	waterstart = 30,
	wateruse = 1,
	night = 5,
	soak = 60,
	soak_damage = 75,
	wither = 25,
	wither_damage = 15,
	doublesize = true,
}

crops.register({ name = "crops:beanpole_plant_base_1", properties = properties })
crops.register({ name = "crops:beanpole_plant_base_2", properties = properties })
crops.register({ name = "crops:beanpole_plant_base_3", properties = properties })
crops.register({ name = "crops:beanpole_plant_base_4", properties = properties })
crops.register({ name = "crops:beanpole_plant_base_5", properties = properties })
