dofile(minetest.get_modpath("trike") .. DIR_DELIM .. "trike_global_definitions.lua")

--
-- entity
--

trike.vector_up = vector.new(0, 1, 0)

minetest.register_entity('trike:engine',{
initial_properties = {
	physical = false,
	collide_with_objects=false,
	pointable=false,
	visual = "mesh",
	mesh = "trike_propeller.b3d",
    --visual_size = {x = 3, y = 3, z = 3},
	textures = {"trike_rotor.png", "trike_black.png",},
	},
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,
	
})

minetest.register_entity('trike:front_wheel',{
initial_properties = {
	physical = false,
	collide_with_objects=false,
	pointable=false,
	visual = "mesh",
	mesh = "trike_front_wheel.b3d",
    --visual_size = {x = 3, y = 3, z = 3},
	textures = {"trike_metal.png", "trike_black.png", "trike_metal.png",},
	},
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,
	
})

minetest.register_entity('trike:wing',{
    initial_properties = {
	    physical = false,
	    collide_with_objects=true,
	    pointable=false,
	    visual = "mesh",
	    mesh = "trike_wing.b3d",
        backface_culling = false,
	    textures = {"trike_black.png", "trike_black.png", "trike_metal.png", "trike_wing_color.png", "trike_wing.png"},
	},
    _color="",
	
    on_activate = function(self, std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,

})

--
-- fuel
--
minetest.register_entity('trike:pointer',{
initial_properties = {
	physical = false,
	collide_with_objects=false,
	pointable=false,
	visual = "mesh",
	mesh = "pointer.b3d",
    visual_size = {x = 0.4, y = 0.4, z = 0.4},
	textures = {"trike_grey.png"},
	},
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,
})

--
-- seat pivot
--
minetest.register_entity('trike:seat_base',{
initial_properties = {
	physical = false,
	collide_with_objects=false,
	pointable=false,
	visual = "mesh",
	mesh = "trike_seat_base.b3d",
    textures = {"trike_black.png",},
	},
	
    on_activate = function(self,std)
	    self.sdata = minetest.deserialize(std) or {}
	    if self.sdata.remove then self.object:remove() end
    end,
	    
    get_staticdata=function(self)
      self.sdata.remove=true
      return minetest.serialize(self.sdata)
    end,
	
})

minetest.register_entity("trike:trike", {
	initial_properties = {
	    physical = true,
        collide_with_objects = true,
	    collisionbox = {-1.2, 0.0, -1.2, 1.2, 3, 1.2}, --{-1,0,-1, 1,0.3,1},
	    selectionbox = {-2, 0, -2, 2, 1, 2},
	    visual = "mesh",
	    mesh = "trike_body.b3d",
        stepheight = 0.5,
        textures = {"trike_black.png", "trike_metal.png", "trike_metal.png", "trike_metal.png",
                    "trike_metal.png", "trike_metal.png", "trike_painting.png", "trike_black.png",
                    "trike_white.png", "trike_black.png", "trike_black.png", "trike_black.png",
                    "trike_grey.png", "trike_panel.png", "trike_black.png", "trike_metal.png", "trike_black.png"},
    },
    textures = {},
	driver_name = nil,
	sound_handle = nil,
    owner = "",
    static_save = true,
    infotext = "A nice ultralight",
    hp_max = 50,
    buoyancy = 2,
    physics = trike.physics,
    _passenger = nil,
    _color = "#0063b0",
    _rudder_angle = 0,
    _acceleration = 0,
    _engine_running = false,
    _angle_of_attack = 2,
    _power_lever = 0,
    _energy = 0.001,
    _longit_speed = 0,
    _lastrot = {x=0,y=0,z=0},
    _last_accell = {x=0,y=0,z=0},

    get_staticdata = function(self) -- unloaded/unloads ... is now saved
        return minetest.serialize({
            stored_energy = self._energy,
            stored_owner = self.owner,
            stored_hp = self.hp_max,
            stored_color = self._color,
            stored_power_lever = self._power_lever,
            stored_driver_name = self.driver_name,
        })
    end,

	on_activate = function(self, staticdata, dtime_s)
        mobkit.actfunc(self, staticdata, dtime_s)
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.deserialize(staticdata) or {}
            self._energy = data.stored_energy
            self.owner = data.stored_owner
            self.hp_max = data.stored_hp
            self._color = data.stored_color
            self._power_lever = data.stored_power_lever
            self.driver_name = data.stored_driver_name
            --minetest.debug("loaded: ", self._energy)
        end
        trike.setText(self)
        self.object:set_animation({x = 1, y = 12}, 0, 0, true)

        local pos = self.object:get_pos()

	    local engine=minetest.add_entity(pos,'trike:engine')
	    engine:set_attach(self.object,'',{x=0,y=0,z=0},{x=0,y=0,z=0})
		-- set the animation once and later only change the speed
        engine:set_animation({x = 1, y = 12}, 0, 0, true)
	    self.engine = engine

	    local wing=minetest.add_entity(pos,'trike:wing')
	    wing:set_attach(self.object,'',{x=0,y=29,z=0},{x=0,y=0,z=0})
	    self.wing = wing

	    local wheel=minetest.add_entity(pos,'trike:front_wheel')
	    wheel:set_attach(self.object,'',{x=0,y=0,z=0},{x=0,y=0,z=0})
		-- set the animation once and later only change the speed
        wheel:set_animation({x = 1, y = 12}, 0, 0, true)
	    self.wheel = wheel

	    local fuel_gauge=minetest.add_entity(pos,'trike:pointer')
        local energy_indicator_angle = trike.get_gauge_angle(self._energy)
	    fuel_gauge:set_attach(self.object,'',TRIKE_GAUGE_FUEL_POSITION,{x=0,y=0,z=energy_indicator_angle})
	    self.fuel_gauge = fuel_gauge

	    local power_gauge=minetest.add_entity(pos,'trike:pointer')
        local power_indicator_angle = trike.get_gauge_angle(self._power_lever)
	    power_gauge:set_attach(self.object,'',TRIKE_GAUGE_POWER_POSITION,{x=0,y=0,z=power_indicator_angle})
	    self.power_gauge = power_gauge

	    local climb_gauge=minetest.add_entity(pos,'trike:pointer')
        local climb_angle = trike.get_gauge_angle(0)
	    climb_gauge:set_attach(self.object,'',TRIKE_GAUGE_CLIMBER_POSITION,{x=0,y=0,z=climb_angle})
	    self.climb_gauge = climb_gauge

        local pilot_seat_base=minetest.add_entity(pos,'trike:seat_base')
        pilot_seat_base:set_attach(self.object,'',{x=0,y=7,z=8},{x=0,y=0,z=0})
	    self.pilot_seat_base = pilot_seat_base

        local passenger_seat_base=minetest.add_entity(pos,'trike:seat_base')
        passenger_seat_base:set_attach(self.object,'',{x=0,y=9,z=1.6},{x=0,y=0,z=0})
	    self.passenger_seat_base = passenger_seat_base

        trike.paint(self, self.object, self._color, "trike_painting.png")
        trike.paint(self, self.wing, self._color, "trike_wing_color.png")

		self.object:set_armor_groups({immortal=1})
	end,

    --on_step = mobkit.stepfunc,
    on_step = function(self,dtime,colinfo)
	    self.dtime = math.min(dtime,0.2)
	    self.colinfo = colinfo
	    self.height = mobkit.get_box_height(self)
	    
    --  physics comes first
	    local vel = self.object:get_velocity()
	    
	    if colinfo then 
		    self.isonground = colinfo.touching_ground
	    else
		    if self.lastvelocity.y==0 and vel.y==0 then
			    self.isonground = true
		    else
			    self.isonground = false
		    end
	    end
	    
	    self:physics()

	    if self.logic then
		    self:logic()
	    end
	    
	    self.lastvelocity = self.object:get_velocity()
	    self.time_total=self.time_total+self.dtime
    end,

    logic = trike.flightstep,

	on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
		if not puncher or not puncher:is_player() then
			return
		end
        local is_admin = false
        is_admin = minetest.check_player_privs(puncher, {server=true})
		local name = puncher:get_player_name()
        if self.owner and self.owner ~= name and self.owner ~= "" then
            if is_admin == false then return end
        end
        if self.owner == nil then
            self.owner = name
        end
        	
        if self.driver_name and self.driver_name ~= name then
			-- do not allow other players to remove the object while there is a driver
			return
		end
        
        local is_attached = false
        if puncher:get_attach() == self.object then is_attached = true end

        local itmstck=puncher:get_wielded_item()
        local item_name = ""
        if itmstck then item_name = itmstck:get_name() end

        if is_attached == false then
            if trike.loadFuel(self, puncher:get_player_name()) then
                return
            end

            --repair
            if item_name == "trike:repair_tool" and self._engine_running == false  then
                if self.hp_max < 50 then
                    local inventory_item = "default:steel_ingot"
                    local inv = puncher:get_inventory()
                    if inv:contains_item("main", inventory_item) then
                        local stack = ItemStack(inventory_item .. " 1")
                        inv:remove_item("main", stack)
                        self.hp_max = self.hp_max + 10
                        if self.hp_max > 50 then self.hp_max = 50 end
                        trike.setText(self)
                    end
                end
                return
            end

            -- deal with painting or destroying
		    if itmstck then
			    local _,indx = item_name:find('dye:')
			    if indx then

                    --lets paint!!!!
				    local color = item_name:sub(indx+1)
				    local colstr = trike.colors[color]
                    --minetest.chat_send_all(color ..' '.. dump(colstr))
				    if colstr then
                        trike.paint(self, self.object, colstr, "trike_painting.png")
                        trike.paint(self, self.wing, colstr, "trike_wing_color.png")
					    itmstck:set_count(itmstck:get_count()-1)
					    puncher:set_wielded_item(itmstck)
				    end
                    -- end painting

			    else -- deal damage
				    if not self.driver and toolcaps and toolcaps.damage_groups and
                            toolcaps.damage_groups.fleshy and item_name ~= trike.fuel then
					    --mobkit.hurt(self,toolcaps.damage_groups.fleshy - 1)
					    --mobkit.make_sound(self,'hit')
                        self.hp_max = self.hp_max - 10
                        minetest.sound_play("collision", {
	                        object = self.object,
	                        max_hear_distance = 5,
	                        gain = 1.0,
                            fade = 0.0,
                            pitch = 1.0,
                        })
                        trike.setText(self)
				    end
			    end
            end

            if self.hp_max <= 0 then
                trike.destroy(self)
            end

        end
        
	end,

	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end

        local name = clicker:get_player_name()

        if self.owner == "" then
            self.owner = name
        end

        if self.owner == name then
            -- pilot section
            local can_access = true
            if trike.restricted == "true" then
                can_access = minetest.check_player_privs(clicker, {flight_licence=true})
            end
            if can_access then
	            if name == self.driver_name then
                    -- eject passenger if the plane is on ground
                    local touching_ground, liquid_below = trike.check_node_below(self.object)
                    if self.isinliquid or touching_ground or liquid_below then --isn't flying?
                        if self._passenger then
                            local passenger = minetest.get_player_by_name(self._passenger)
                            if passenger then trike.dettach_pax(self, passenger) end
                        end
                    end
                    trike.dettachPlayer(self, clicker)
	            elseif not self.driver_name then
                    local is_under_water = trike.check_is_under_water(self.object)
                    if is_under_water then return end
                    -- no driver => clicker is new driver
                    trike.attach(self, clicker)
	            end
            else
                minetest.show_formspec(name, "trike:flightlicence",
                    "size[4,2]" ..
                    "label[0.0,0.0;Sorry ...]"..
                    "label[0.0,0.7;You need a flight licence to fly it.]" ..
                    "label[0.0,1.0;You must obtain it from server admin.]" ..
                    "button_exit[1.5,1.9;0.9,0.1;e;Exit]")
            end
            -- end pilot section
        else
            --passenger section
            --only can enter when the pilot is inside
            if self.driver_name then
                if self._passenger == nil then
                    trike.attach_pax(self, clicker)
                else
                    trike.dettach_pax(self, clicker)
                end
            else
                if self._passenger then
                    trike.dettach_pax(self, clicker)
                end
            end
        end
	end,
})
