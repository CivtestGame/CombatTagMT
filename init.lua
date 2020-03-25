--[[

init.lua

Entrypoint to this plugin.

--]]

combat_tag = {}

minetest.debug("CombatTagMT initialised")

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath .. "/combattag.lua")
dofile(modpath .. "/hud.lua")

return combat_tag
