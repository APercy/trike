function trike.loadFuel(self, player_name)
    if self._energy < 9.5 then 
        local player = minetest.get_player_by_name(player_name)
        local inv = player:get_inventory()

        local stack = nil
        if inv:contains_item("main", trike.fuel) then
            stack = ItemStack(trike.fuel .. " 1")
        end

        if stack then
            local taken = inv:remove_item("main", stack)

	        self._energy = self._energy + 1
            if self._energy > 10 then self._energy = 10 end

            local energy_indicator_angle = trike.get_gauge_angle(self._energy)
            self.fuel_gauge:set_attach(self.object,'',TRIKE_GAUGE_FUEL_POSITION,{x=0,y=0,z=energy_indicator_angle})
	    end
    else
        print("Full tank.")
    end
end

function trike.consumptionCalc(self, accel)
    if accel == nil then return end
    if self._energy > 0 and self._engine_running and accel ~= nil then
        local zero_reference = vector.new()
        local acceleration = trike.get_hipotenuse_value(accel, zero_reference)
        local consumed_power = self._power_lever/700000
        --minetest.chat_send_all('consumed: '.. consumed_power)
        self._energy = self._energy - consumed_power;

        local energy_indicator_angle = trike.get_gauge_angle(self._energy)
        if self.fuel_gauge:get_luaentity() then
            self.fuel_gauge:set_attach(self.object,'',TRIKE_GAUGE_FUEL_POSITION,{x=0,y=0,z=energy_indicator_angle})
        else
            --in case it have lost the entity by some conflict
            --self.fuel_gauge=minetest.add_entity(TRIKE_GAUGE_POINTER_POSITION,'trike:pointer')
            --self.fuel_gauge:set_attach(self.object,'',TRIKE_GAUGE_FUEL_POSITION,{x=0,y=0,z=energy_indicator_angle})
        end
    end
    if self._energy <= 0 and self._engine_running and accel ~= nil then
        self._engine_running = false
        if self.sound_handle then minetest.sound_stop(self.sound_handle) end
	    self.engine:set_animation_frame_speed(0)
    end
end
