
--[[

Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

"crops" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

crops = {}

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

-- crop nodes, crafts, craftitems
dofile(modpath .. "/melon.lua")
dofile(modpath .. "/corn.lua")
dofile(modpath .. "/tomato.lua")
dofile(modpath .. "/potato.lua")
dofile(modpath .. "/polebean.lua")

-- cooking recipes that mix craftitems
dofile(modpath .. "/cooking.lua")

minetest.log("action", "[crops] loaded.")
