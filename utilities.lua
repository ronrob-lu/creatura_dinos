-- Shared Creatura mob utilities for Dinosaurs mod

if not creatura.registered_utilities["dinos:wander"] then
	creatura.register_utility("dinos:wander", function(self)
		local timer = math.random(4, 10)
		local goal
		local function func(self)
			timer = timer - (self.dtime or 0.1)
			if timer <= 0 then
				self:halt()
				return true
			end
			if not goal then
				local pos = self.object:get_pos()
				if pos then
					local angle = math.random() * math.pi * 2
					local dist = math.random(6, 14)
					goal = {
						x = pos.x + math.cos(angle) * dist,
						y = pos.y,
						z = pos.z + math.sin(angle) * dist
					}
				end
			end
			if goal then
				self:animate("walk")
				if self:move(goal, "creatura:obstacle_avoidance", 0.5, "walk") then
					self:halt()
					return true
				end
			end
		end
		self:set_utility(func)
	end)
end

if not creatura.registered_utilities["dinos:flee"] then
	creatura.register_utility("dinos:flee", function(self, threat)
		local timer = math.random(5, 8)
		local function func(self)
			timer = timer - (self.dtime or 0.1)
			if timer <= 0 or not creatura.is_valid(threat) then
				self:halt()
				return true
			end
			local pos = self.object:get_pos()
			local tpos = threat:get_pos()
			if not pos or not tpos then
				self:halt()
				return true
			end
			local dir = vector.direction(tpos, pos)
			local goal = {x = pos.x + dir.x * 15, y = pos.y, z = pos.z + dir.z * 15}
			self:animate("run")
			if self:move(goal, "creatura:obstacle_avoidance", 1.2, "run") then
				self:halt()
				return true
			end
		end
		self:set_utility(func)
	end)
end

if not creatura.registered_utilities["dinos:counter_attack"] then
	creatura.register_utility("dinos:counter_attack", function(self, target)
		local attack_timer = 0
		local function func(self)
			if not creatura.is_valid(target) or not creatura.is_alive(target) then
				self:halt()
				return true
			end
			local pos = self.object:get_pos()
			local tpos = target:get_pos()
			if not pos or not tpos then
				self:halt()
				return true
			end
			local dist = vector.distance(pos, tpos)
			local reach = (self.width or 1) + 1.5
			if dist <= reach then
				self:halt()
				local dir = vector.direction(pos, tpos)
				self:turn_to(minetest.dir_to_yaw(dir))
				self:animate("attack")
				attack_timer = attack_timer + (self.dtime or 0.1)
				if attack_timer >= 0.5 then
					self:punch_target(target)
					attack_timer = 0
				end
			else
				self:animate("run")
				self:move(tpos, "creatura:obstacle_avoidance", 1.0, "run")
			end
		end
		self:set_utility(func)
	end)
end

if not creatura.registered_utilities["dinos:hunt"] then
	creatura.register_utility("dinos:hunt", function(self, target)
		local attack_timer = 0
		local function func(self)
			if not creatura.is_valid(target) or not creatura.is_alive(target) then
				self:halt()
				return true
			end
			local pos = self.object:get_pos()
			local tpos = target:get_pos()
			if not pos or not tpos then
				self:halt()
				return true
			end
			local dist = vector.distance(pos, tpos)
			local reach = (self.width or 1) + 1.8
			if dist <= reach then
				self:halt()
				local dir = vector.direction(pos, tpos)
				self:turn_to(minetest.dir_to_yaw(dir))
				self:animate("attack")
				attack_timer = attack_timer + (self.dtime or 0.1)
				if attack_timer >= 0.5 then
					self:punch_target(target)
					attack_timer = 0
				end
			else
				self:animate("run")
				self:move(tpos, "creatura:obstacle_avoidance", 1.0, "run")
			end
		end
		self:set_utility(func)
	end)
end
