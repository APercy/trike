-- engine
minetest.register_craftitem("trike:wing",{
	description = "Trike wing",
	inventory_image = "icon3.png",
})
-- hull
minetest.register_craftitem("trike:fuselage",{
	description = "Trike body",
	inventory_image = "icon2.png",
})


-- trike
minetest.register_craftitem("trike:trike", {
	description = "Ultralight Trike",
	inventory_image = "icon1.png",
    liquids_pointable = false,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
        
        local pointed_pos = pointed_thing.under
        local node_below = minetest.get_node(pointed_pos).name
        local nodedef = minetest.registered_nodes[node_below]
        if nodedef.liquidtype == "none" then
			pointed_pos.y=pointed_pos.y+1.5
			local trike = minetest.add_entity(pointed_pos, "trike:trike")
			if trike and placer then
                local ent = trike:get_luaentity()
                local owner = placer:get_player_name()
                ent.owner = owner
				trike:set_yaw(placer:get_look_horizontal())
				itemstack:take_item()
			end
        end

		return itemstack
	end,
})

-- trike repair
minetest.register_craftitem("trike:repair_tool",{
	description = "Trike repair tool",
	inventory_image = "repair_tool.png",
})

--
-- crafting
--

if minetest.get_modpath("default") then
	minetest.register_craft({
		output = "trike:wing",
		recipe = {
			{"",           "wool:white",          ""          },
			{"wool:white", "default:steel_ingot", "wool:white"},
			{"farming:string", "wool:white",      "farming:string"},
		}
	})
	minetest.register_craft({
		output = "trike:fuselage",
		recipe = {
			{"",                    "default:diamondblock", ""},
			{"default:steel_ingot", "default:steel_ingot",  "default:steel_ingot"},
			{"default:steel_ingot", "default:mese_block",   "default:steel_ingot"},
		}
	})
	minetest.register_craft({
		output = "trike:trike",
		recipe = {
			{"",                  ""},
			{"trike:fuselage", "trike:wing"},
		}
	})
    minetest.register_craft({
	    output = "trike:repair_tool",
	    recipe = {
		    {"default:steel_ingot", "", "default:steel_ingot"},
		    {"", "default:steel_ingot", ""},
		    {"", "default:steel_ingot", ""},
	    },
    })
end
