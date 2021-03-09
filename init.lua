trike={}
trike.gravity = tonumber(minetest.settings:get("movement_gravity")) or 9.8

trike.colors ={
    black='#2b2b2b',
    blue='#0063b0',
    brown='#8c5922',
    cyan='#07B6BC',
    dark_green='#567a42',
    dark_grey='#6d6d6d',
    green='#4ee34c',
    grey='#9f9f9f',
    magenta='#ff0098',
    orange='#ff8b0e',
    pink='#ff62c6',
    red='#dc1818',
    violet='#a437ff',
    white='#FFFFFF',
    yellow='#ffe400',
}

dofile(minetest.get_modpath("trike") .. DIR_DELIM .. "trike_crafts.lua")
dofile(minetest.get_modpath("trike") .. DIR_DELIM .. "trike_control.lua")
dofile(minetest.get_modpath("trike") .. DIR_DELIM .. "trike_fuel_management.lua")
dofile(minetest.get_modpath("trike") .. DIR_DELIM .. "trike_custom_physics.lua")
dofile(minetest.get_modpath("trike") .. DIR_DELIM .. "trike_utilities.lua")
dofile(minetest.get_modpath("trike") .. DIR_DELIM .. "trike_entities.lua")

--
-- helpers and co.
--

local creative_exists = minetest.global_exists("creative")

--
-- items
--

settings = Settings(minetest.get_worldpath() .. "/trike_settings.conf")
local function fetch_setting(name)
    local sname = name
    return settings and settings:get(sname) or minetest.settings:get(sname)
end

trike.restricted = fetch_setting("restricted")

minetest.register_privilege("flight_licence", {
    description = "Gives a flight licence to the player",
    give_to_singleplayer = true
})


