dofile(minetest.get_modpath("trike") .. DIR_DELIM .. "trike_global_definitions.lua")

function trike.get_hipotenuse_value(point1, point2)
    return math.sqrt((point1.x - point2.x) ^ 2 + (point1.y - point2.y) ^ 2 + (point1.z - point2.z) ^ 2)
end

function trike.dot(v1,v2)
	return v1.x*v2.x+v1.y*v2.y+v1.z*v2.z
end

function trike.sign(n)
	return n>=0 and 1 or -1
end

function trike.minmax(v,m)
	return math.min(math.abs(v),m)*trike.sign(v)
end

--lift
local function pitchroll2pitchyaw(aoa,roll)
	if roll == 0.0 then return aoa,0 end 
	-- assumed vector x=0,y=0,z=1
	local p1 = math.tan(aoa)
	local y = math.cos(roll)*p1
	local x = math.sqrt(p1^2-y^2)
	local pitch = math.atan(y)
	local yaw=math.atan(x)*math.sign(roll)
	return pitch,yaw
end

function trike.getLiftAccel(self, velocity, accel, longit_speed, roll)
    --lift calculations
    -----------------------------------------------------------
    local max_height = 2500
    
    local retval = accel
    if longit_speed > 1.0 then
        local angle_of_attack = math.rad(self._angle_of_attack)
        local lift = 14
        local acc = 0.8
        local daoa = deg(angle_of_attack)

    	local curr_pos = self.object:get_pos()
        local curr_percent_height = (100 - ((curr_pos.y * 100) / max_height))/100 --to decrease the lift coefficient at hight altitudes

	    local rotation=self.object:get_rotation()
	    local vrot = mobkit.dir_to_rot(velocity,rotation)
	    
	    hpitch,hyaw = pitchroll2pitchyaw(angle_of_attack,roll)

	    local hrot = {x=vrot.x+hpitch,y=vrot.y-hyaw,z=roll}
	    local hdir = mobkit.rot_to_dir(hrot) --(hrot)
	    local cross = vector.cross(velocity,hdir)
	    local lift_dir = vector.normalize(vector.cross(cross,hdir))	

        local lift_coefficient = (0.24*abs(daoa)*(1/(0.025*daoa+3))^4*math.sign(angle_of_attack))
        local lift_val = (lift*(vector.length(velocity)^2)*lift_coefficient)*curr_percent_height
        --minetest.chat_send_all('lift: '.. lift_val)

        local lift_acc = vector.multiply(lift_dir,lift_val)
        lift_acc=vector.add(vector.multiply(minetest.yaw_to_dir(rotation.y),acc),lift_acc)

        retval = vector.add(accel,lift_acc)
    end
    -----------------------------------------------------------
    -- end lift
    return retval
end


function trike.get_gauge_angle(value)
    local angle = value * 18
    angle = angle - 90
    angle = angle * -1
	return angle
end

-- attach player
function trike.attach(self, player)
    local name = player:get_player_name()
    self.driver_name = name

    -- attach the driver
    player:set_attach(self.object, "", {x = 0, y = 7, z = 8}, {x = 0, y = 0, z = 0})
    player:set_eye_offset({x = 0, y = 1, z = 7}, {x = 0, y = 1, z = 7})
    player_api.player_attached[name] = true
    -- make the driver sit
    minetest.after(0.2, function()
        local player = minetest.get_player_by_name(name)
        if player then
	        player_api.set_animation(player, "sit")
        end
    end)
    -- disable gravity
    self.object:set_acceleration(vector.new())
end

-- attach player
function trike.attach_pax(self, player)
    local name = player:get_player_name()
    self._passenger = name

    -- attach the driver
    player:set_attach(self.object, "", {x = 0, y = 9, z = 1.6}, {x = 0, y = 0, z = 0})
    player:set_eye_offset({x = 0, y = 7, z = 2}, {x = 0, y = 3, z = -30})
    player_api.player_attached[name] = true
    -- make the driver sit
    minetest.after(0.2, function()
        local player = minetest.get_player_by_name(name)
        if player then
	        player_api.set_animation(player, "sit")
        end
    end)
end

function trike.detachPlayer(self, player)
    local name = self.driver_name
    trike.setText(self)

    self._engine_running = false

    -- driver clicked the object => driver gets off the vehicle
    self.driver_name = nil
    -- sound and animation
    if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
    end
    
    self.engine:set_animation_frame_speed(0)

    -- detach the player
    player:set_detach()
    player_api.player_attached[name] = nil
    player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
    player_api.set_animation(player, "stand")
    self.driver = nil
    self.object:set_acceleration(vector.multiply(trike.vector_up, -trike.gravity))
end

function trike.detach_pax(self, player)
    local name = self._passenger
    trike.setText(self)

    -- passenger clicked the object => driver gets off the vehicle
    self._passenger = nil
    -- sound and animation
    if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
    end
    
    self.engine:set_animation_frame_speed(0)

    -- detach the player
    player:set_detach()
    player_api.player_attached[name] = nil
    player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
    player_api.set_animation(player, "stand")
end

function trike.checkAttach(self)
    if self.owner then
        local player = minetest.get_player_by_name(self.owner)
        
        if player then
            local player_attach = player:get_attach()
            if player_attach then
                if player_attach == self.object then
                    return true
                end
            end
        end
    end
    return false
end

--painting
function trike.paint(self, object, colstr, search_string)
    if colstr then
        self._color = colstr
        local entity = object:get_luaentity()
        local l_textures = entity.initial_properties.textures
        for _, texture in ipairs(l_textures) do
            local i,indx = texture:find(search_string)
            if indx then
                l_textures[_] = search_string .."^[multiply:".. colstr
            end
        end
        object:set_properties({textures=l_textures})
    end
end

-- destroy the boat
function trike.destroy(self)
    if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
    end

    if self._passenger then
        -- detach the passenger
        local passenger = minetest.get_player_by_name(self._passenger)
        if passenger then 
            passenger:set_detach()
            passenger:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
            player_api.player_attached[self._passenger] = nil
            -- player should stand again
            player_api.set_animation(passenger, "stand")
        end
        self._passenger = nil
    end

    if self.driver_name then
        -- detach the driver
        local player = minetest.get_player_by_name(self.driver_name)
        player:set_detach()
        player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        player_api.player_attached[self.driver_name] = nil
        -- player should stand again
        player_api.set_animation(player, "stand")
        self.driver_name = nil
    end

    local pos = self.object:get_pos()
    if self.fuel_gauge then self.fuel_gauge:remove() end
    if self.power_gauge then self.power_gauge:remove() end
    if self.climb_gauge then self.climb_gauge:remove() end
    if self.engine then self.engine:remove() end
    if self.wing then self.wing:remove() end
    if self.wheel then self.wheel:remove() end

    self.object:remove()

    pos.y=pos.y+2
    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'trike:wing')

    for i=1,6 do
	    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:mese_crystal')
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:diamond')
    end

    for i=1,3 do
	    minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'default:steel_ingot')
    end

    --minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'trike:trike')

    --local total_biofuel = math.floor(self._energy) - 1
    --for i=0,total_biofuel do
        --minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},'biofuel:biofuel')
    --end
end

function trike.check_node_below(obj)
    local pos_below = obj:get_pos()
    if pos_below then
        pos_below.y = pos_below.y - 0.1
        local node_below = minetest.get_node(pos_below).name
        local nodedef = minetest.registered_nodes[node_below]
        local touching_ground = not nodedef or -- unknown nodes are solid
		        nodedef.walkable or false
        local liquid_below = not touching_ground and nodedef.liquidtype ~= "none"
        return touching_ground, liquid_below
    end
    return nil, nil
end

function trike.setText(self)
    local properties = self.object:get_properties()
    local formatted = string.format(
       "%.2f", self.hp_max
    )
    if properties then
        properties.infotext = "Nice ultralight trike of " .. self.owner .. ". Current hp: " .. formatted
        self.object:set_properties(properties)
    end
end

function trike.testImpact(self, velocity)
    collision = false
    if self._last_vel == nil then return end
    local impact = abs(trike.get_hipotenuse_value(velocity, self._last_vel))
    if impact > 2 then
        --minetest.chat_send_all('impact: '.. impact .. ' - hp: ' .. self.hp_max)
        local p = self.object:get_pos()
		local nodeu = mobkit.nodeatpos(mobkit.pos_shift(p,{y=1}))
		local noded = mobkit.nodeatpos(mobkit.pos_shift(p,{y=-1}))
        local nodel = mobkit.nodeatpos(mobkit.pos_shift(p,{x=-1}))
        local noder = mobkit.nodeatpos(mobkit.pos_shift(p,{x=1}))
        local nodef = mobkit.nodeatpos(mobkit.pos_shift(p,{z=1}))
        local nodeb = mobkit.nodeatpos(mobkit.pos_shift(p,{z=-1}))
		if (nodeu and nodeu.drawtype ~= 'airlike') or
            (noded and noded.drawtype ~= 'airlike') or
            (nodef and nodef.drawtype ~= 'airlike') or 
            (nodeb and nodeb.drawtype ~= 'airlike') or 
            (noder and noder.drawtype ~= 'airlike') or 
            (nodel and nodel.drawtype ~= 'airlike') then
			collision = true
		end
    end
    if collision then
        local damage = impact / 2
        self.hp_max = self.hp_max - damage --subtract the impact value directly to hp meter
        local curr_pos = self.object:get_pos()

        if self.driver_name then
            minetest.sound_play("collision", {
                to_player = self.driver_name,
                --pos = curr_pos,
                --max_hear_distance = 5,
                gain = 1.0,
                fade = 0.0,
                pitch = 1.0,
            })

            local player_name = self.driver_name
            trike.setText(self)

            --minetest.chat_send_all('damage: '.. damage .. ' - hp: ' .. self.hp_max)
            if self.hp_max < 0 then --if acumulated damage is greater than 50, adieu
                trike.destroy(self)   
            end

            local player = minetest.get_player_by_name(player_name)
            if player then
		        if player:get_hp() > 0 then
			        player:set_hp(player:get_hp()-(damage/2))
		        end
            end
            if self._passenger ~= nil then
                local passenger = minetest.get_player_by_name(self._passenger)
                if passenger then
		            if passenger:get_hp() > 0 then
			            passenger:set_hp(passenger:get_hp()-(damage/2))
		            end
                end
            end
        end

    end
end

function trike.checkattachBug(self)
    -- for some engine error the player can be detached from the submarine, so lets set him attached again
    local can_stop = true
    if self.owner and self.driver_name then
        -- attach the driver again
        local player = minetest.get_player_by_name(self.owner)
        if player then
		    if player:get_hp() > 0 then
                trike.attach(self, player)
                can_stop = false
            else
                trike.detachPlayer(self, player)
		    end
        end
    end

    if can_stop then
        --detach player
        if self.sound_handle ~= nil then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
        end
    end
end

function trike.check_is_under_water(obj)
	local pos_up = obj:get_pos()
	pos_up.y = pos_up.y + 0.1
	local node_up = minetest.get_node(pos_up).name
	local nodedef = minetest.registered_nodes[node_up]
	local liquid_up = nodedef.liquidtype ~= "none"
	return liquid_up
end

