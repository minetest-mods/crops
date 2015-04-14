
--[[

Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

"crops" is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1
of the license, or (at your option) any later version.

--]]

local crops_interval = 30
local crops_chance = 8

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/melon.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/corn.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/tomato.lua")

minetest.log("action", "[crops] loaded.")
