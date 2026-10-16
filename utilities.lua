--------------------
-- Dinos Mob AI   --
-- (Creatura API) --
--------------------

dinos = dinos or {}
dinos.mob_ai = {}

-- Math & Vector Helpers --

local abs = math.abs
local atan2 = math.atan2 or math.atan
local cos = math.cos
local floor = math.floor
local max = math.max
local min = math.min
local pi = math.pi
local pi2 = pi * 2
local rad = math.rad
local random = math.random
local sin = math.sin

local vec_add = vector.add
local vec_dir = vector.direction
local vec_dist = vector.distance
local vec_dot = vector.dot
local vec_multi = vector.multiply
local vec_normal = vector.normalize
local vec_round = vector.round

local dir2yaw = minetest.dir_to_yaw
local yaw2dir = minetest.yaw_to_dir

local function diff(a, b)
	return atan2(sin(b - a), cos(b - a))
end

local function clamp(val, minn, maxn)
	if val < minn then
		return minn
	elseif val > maxn then
		return maxn
	end
	return val
end

local function contains_val(tbl, val)
	if type(tbl) ~= "table" then return false end
	for _, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

-- Safe Nearby Object / Player Queries --

function dinos.get_nearby_objects(self, name, range)
	local pos = self.object and self.object:get_pos()
	if not pos then return {} end
	local stored = self._nearby_objs or {}
	local objects = (#stored > 0 and not range and stored) or self:store_nearby_objects(range) or {}
	local nearby = {}
	for _, object in ipairs(objects) do
		local ent = creatura.is_alive(object) and object:get_luaentity()
		if ent
		and object ~= self.object
		and not ent._ignore
		and (not name
			or (type(name) == "table" and contains_val(name, ent.name))
			or ent.name == name) then
			table.insert(nearby, object)
		end
	end
	return nearby
end

function dinos.get_nearby_object(self, name, range)
	local list = dinos.get_nearby_objects(self, name, range)
	return list[1]
end

function dinos.get_nearby_player(self, range)
	local pos = self.object and self.object:get_pos()
	if not pos then return nil end
	local stored = self._nearby_objs or {}
	local objects = (#stored > 0 and not range and stored) or self:store_nearby_objects(range) or {}
	for _, object in ipairs(objects) do
		if object:is_player()
		and creatura.is_alive(object) then
			return object
		end
	end
	return nil
end

function dinos.get_average_pos(vectors)
	if not vectors or #vectors < 1 then return nil end
	local sum = {x = 0, y = 0, z = 0}
	for _, vec in ipairs(vectors) do
		sum = vec_add(sum, vec)
	end
	return vector.divide(sum, #vectors)
end

local function get_group_positions(self)
	local objects = dinos.get_nearby_objects(self, self.name)
	local group = {}
	for _, object in ipairs(objects) do
		local obj_pos = object and object:get_pos()
		if obj_pos then
			table.insert(group, obj_pos)
		end
	end
	return group
end

function dinos.find_collision(self, dir)
	local pos = self.object and self.object:get_pos()
	if not pos then return nil end
	local pos2 = vec_add(pos, vec_multi(dir, 16))
	local ray = minetest.raycast(pos, pos2, false, false)
	for pointed_thing in ray do
		if pointed_thing.type == "node" then
			return pointed_thing.under
		end
	end
	return nil
end

-- Steering & Movement Methods --

local function get_obstacle(pos, water)
	local pos2 = {x = pos.x, y = pos.y, z = pos.z}
	local n_def = creatura.get_node_def(pos2)
	if n_def.walkable
	or (water and (n_def.groups.liquid or 0) > 0) then
		pos2.y = pos.y + 1
		n_def = creatura.get_node_def(pos2)
		local col_max = n_def.walkable or (water and (n_def.groups.liquid or 0) > 0)
		pos2.y = pos.y - 1
		local col_min = col_max and (n_def.walkable or (water and (n_def.groups.liquid or 0) > 0))
		if col_min then
			return pos
		else
			pos2.y = pos.y + 1
			return pos2
		end
	end
end

function dinos.get_steering_context(self, goal, steer_dir, interest, danger, range)
	local pos = self.object:get_pos()
	if not pos then return interest, danger end
	pos = vec_round(pos)
	local width = self.width or 0.5

	local check_pos = vec_add(pos, steer_dir)
	local collision = get_obstacle(check_pos)
	local unsafe_pos = not collision and not self:is_pos_safe(check_pos) and check_pos

	if collision or unsafe_pos then
		local dir2goal = vec_normal(vec_dir(pos, goal))
		local dir2col = vec_normal(vec_dir(pos, collision or unsafe_pos))
		local dist2col = vec_dist(pos, collision or unsafe_pos) - width
		local dot_score = vec_dot(dir2col, dir2goal)
		local dist_score = (range - dist2col) / range
		interest = interest - dot_score
		danger = dist_score
	end
	return interest, danger
end

function dinos.obstacle_avoidance(self, goal)
	local dir = creatura.calc_steering(self, goal, dinos.get_steering_context)
	local stand_pos = self.stand_pos or self.object:get_pos()
	if stand_pos then
		local lift = creatura.get_avoidance_lift(self, vec_add(stand_pos, dir), 2)
		dir.y = (lift ~= 0 and lift) or dir.y
	end
	return dir
end

local function safe_turn_to(mob, tyaw, rate)
	local yaw = mob.object:get_yaw()
	if yaw then
		local d = diff(yaw, tyaw)
		if abs(d) > 2.4 then
			tyaw = yaw + (d >= 0 and 1.5 or -1.5)
		end
	end
	mob:turn_to(tyaw, rate)
end

creatura.register_movement_method("dinos:steer", function(self)
	local steer_to
	local steer_int = 0
	local radius = 2

	self:set_gravity(-9.8)
	local function func(_self, goal, speed_factor)
		local pos = _self.object:get_pos()
		if not pos or not goal then return true end

		local dist = vec_dist(pos, goal)
		if dist < clamp(_self.width or 0.5, 0.5, 1.5) then
			_self:halt()
			return true
		end

		local dir = vec_dir(pos, goal)
		local vel = (_self.speed or 3) * (speed_factor or 0.5)
		local turn_rate = _self.turn_rate or 5
		local mag = clamp(radius - ((radius - dist) / 1), 0.3, 1)
		vel = vel * mag

		steer_int = (steer_int > 0 and steer_int - _self.dtime) or 1 / max(vel, 1)
		steer_to = (steer_int <= 0 and dinos.obstacle_avoidance(_self, goal)) or steer_to

		safe_turn_to(_self, dir2yaw(steer_to or dir), turn_rate)
		_self:set_forward_velocity(vel)
	end
	return func
end)

-------------
-- Actions --
-------------

function dinos.action_walk(self, time, speed, animation, pos2)
	local timeout = time or 3
	local speed_factor = speed or 0.5
	local anim = animation or "walk"
	local step_dist = (self.width or 1) + 4
	local cur_yaw = self.object:get_yaw() or 0
	local target_yaw = cur_yaw + ((random() - 0.5) * pi * 0.8)

	local function func(mob)
		local pos, yaw = mob.object:get_pos(), mob.object:get_yaw()
		if not pos or not yaw then return true end

		if pos2 and vec_dist(pos, pos2) <= (mob.width or 1) + 1.0 then
			mob:halt()
			return true
		end

		local dir = (pos2 and vec_dir(pos, pos2)) or yaw2dir(target_yaw)
		local goal = vec_add(pos, vec_multi(dir, step_dist))

		local safe = true
		if mob.max_fall then
			safe = mob:is_pos_safe(goal)
		end

		if not safe then
			-- Pick a new heading away from the unsafe edge
			target_yaw = (yaw + pi * 0.75) % pi2
			mob:halt()
			return true
		end

		if timeout <= 0
		or mob:move_to(goal, "dinos:steer", speed_factor) then
			mob:halt()
			return true
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then
			mob:halt()
			return true
		end

		mob:animate(anim)
	end
	self:set_action(func)
end

function dinos.action_pursue(self, target, timeout, method, speed_factor, anim)
	local timer = timeout or 4
	local goal
	local function func(_self)
		local target_alive, line_of_sight, tgt_pos = _self:get_target(target)
		if not target_alive or not tgt_pos then
			_self:halt()
			return true
		end
		local pos = _self.object:get_pos()
		if not pos then return true end

		goal = goal or tgt_pos
		timer = timer - _self.dtime
		_self:animate(anim or "run")

		local reach = (_self.width or 1) + 1.2
		if vec_dist(pos, tgt_pos) <= reach then
			_self:halt()
			return true
		end

		local safe = true
		if _self.max_fall and _self.max_fall > 0 then
			safe = _self:is_pos_safe(goal)
		end

		if line_of_sight and vec_dist(goal, tgt_pos) > 2 then
			goal = tgt_pos
		end

		if timer <= 0
		or not safe
		or _self:move_to(goal, method or "dinos:steer", speed_factor or 1) then
			_self:halt()
			return true
		end
	end
	self:set_action(func)
end

function dinos.action_melee(self, target)
	local stage = 1
	local attack_anim = (self.animations["attack"] and "attack") or (self.animations["melee"] and "melee") or nil
	local idle_anim = (self.animations["stand"] and "stand") or "idle"
	local timeout = 1.2

	local function func(mob)
		local target_alive, _, target_pos = mob:get_target(target)
		if not target_alive or not target_pos then return true end

		local pos = mob.stand_pos or mob.object:get_pos()
		if not pos then return true end
		local dist = vec_dist(pos, target_pos)
		local dir = vec_dir(pos, target_pos)

		safe_turn_to(mob, dir2yaw(dir), (mob.turn_rate or 5) * 1.5)
		local anim = attack_anim and mob:animate(attack_anim, idle_anim)

		if stage == 1 then
			mob:halt()
			mob.object:add_velocity({x = dir.x * 3, y = 1.5, z = dir.z * 3})
			stage = 2
		end

		if stage == 2
		and dist < (mob.width or 1) + 2.0 then
			mob:punch_target(target)
			if target:get_pos() then
				local knockback = minetest.calculate_knockback(
					target, mob.object, 1.0,
					{damage_groups = {fleshy = mob.damage or 5}},
					dir, 2.0, mob.damage or 5
				)
				target:add_velocity({
					x = dir.x * knockback,
					y = max(1.5, dir.y * knockback),
					z = dir.z * knockback
				})
			end
			stage = 3
		end

		if stage == 3
		and (not attack_anim or anim == idle_anim) then
			return true
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then return true end
	end
	self:set_action(func)
end

---------------
-- Utilities --
---------------

-- Death Utility
creatura.register_utility("dinos:die", function(self)
	local anim_def = self.animations and self.animations["death"]
	local timer = 1.5
	if anim_def and anim_def.range and anim_def.speed and anim_def.speed > 0 then
		timer = max(1.2, (anim_def.range.y - anim_def.range.x) / anim_def.speed)
	end
	local init = false
	local function func(_self)
		if not init then
			_self:halt()
			_self:play_sound("death")
			if _self.animations and _self.animations["death"] then
				_self:animate("death")
			else
				creatura.action_fallover(_self)
			end
			init = true
		end
		timer = timer - _self.dtime
		if timer <= 0 then
			local pos = _self.object:get_pos()
			if not pos then return end
			minetest.add_particlespawner({
				amount = 12,
				time = 0.25,
				minpos = {x = pos.x - (_self.width or 0.5), y = pos.y, z = pos.z - (_self.width or 0.5)},
				maxpos = {x = pos.x + (_self.width or 0.5), y = pos.y + 0.5, z = pos.z + (_self.width or 0.5)},
				minacc = {x = 0, y = 2, z = 0},
				maxacc = {x = 0, y = 3, z = 0},
				minvel = {x = random(-1, 1), y = -0.25, z = random(-1, 1)},
				maxvel = {x = random(-2, 2), y = -0.25, z = random(-2, 2)},
				minexptime = 0.75,
				maxexptime = 1,
				minsize = 4,
				maxsize = 6,
				texture = "creatura_smoke_particle.png",
				animation = {
					type = "vertical_frames",
					aspect_w = 4,
					aspect_h = 4,
					length = 1,
				},
				glow = 1
			})
			creatura.drop_items(_self)
			_self.object:remove()
		end
	end
	self:set_utility(func)
end)

-- Swim / Escape Water Utility
creatura.register_utility("dinos:swim_seek_land", function(self)
	local land_pos
	self:set_gravity(-9.8)
	local function func(mob)
		if not land_pos then
			for i = 0, 330, 30 do
				land_pos = dinos.find_collision(mob, yaw2dir(rad(i)))
				if land_pos then
					land_pos = {x = land_pos.x, y = land_pos.y + 1, z = land_pos.z}
					local node = minetest.get_node_or_nil(land_pos)
					if node and node.name == "air" then
						break
					else
						land_pos = nil
					end
				end
			end
			if not land_pos then return true end
		end

		local pos, yaw = mob.object:get_pos(), mob.object:get_yaw()
		if not pos or not yaw then return true end

		local tyaw = dir2yaw(vec_dir(pos, land_pos))
		if abs(diff(yaw, tyaw)) > 0.1 then
			safe_turn_to(mob, tyaw, 8)
		end

		mob:set_forward_velocity((mob.speed or 3) * 0.6)
		mob:animate("walk")
		if vec_dist(pos, land_pos) < 1.5
		or (not mob.in_liquid and mob.touching_ground) then
			mob:halt()
			return true
		end
	end
	self:set_utility(func)
end)

-- Wander Utility (with Herding, Grazing, and Skittish awareness)
creatura.register_utility("dinos:wander", function(self)
	local idle_max = 4
	local move_chance = 2
	local range = self.tracking_range or 16
	local center
	local idle_streak = 0

	local function func(mob)
		local pos = mob.stand_pos or mob.object:get_pos()
		if not pos then return true end

		if mob:timer(2) then
			-- Herding behavior: stay near same-species herd
			if mob.is_herding_mob then
				local avg = dinos.get_average_pos(get_group_positions(mob))
				if avg and vec_dist(pos, avg) > range / 4 then
					center = avg
				else
					center = nil
				end
			end

			-- Skittish behavior: gently drift away from close players/predators
			if mob.is_skittish_mob then
				local threat = (mob.predators and dinos.get_nearby_object(mob, mob.predators))
					or dinos.get_nearby_player(mob, 8)
				local alive, los, tpos = mob:get_target(threat)
				if alive and los and tpos then
					center = vec_add(pos, vec_multi(vec_dir(tpos, pos), 6))
				end
			end
		end

		if not mob:get_action() then
			if center or idle_streak >= 1 or random(move_chance) < 2 then
				dinos.action_walk(mob, random(3, 5), 0.5, "walk", center)
				center = nil
				idle_streak = 0
			else
				creatura.action_idle(mob, random(2, idle_max), "idle")
				idle_streak = idle_streak + 1
			end
		end
	end
	self:set_utility(func)
end)

-- Follow Wielded Food Utility
creatura.register_utility("dinos:follow", function(self, player)
	local function func(mob)
		if not player or not creatura.is_alive(player) or not mob:follow_wielded_item(player) then
			return true
		end
		local pos, target_pos = mob.object:get_pos(), player:get_pos()
		if not pos or not target_pos then return true end

		if not mob:get_action() then
			local dist = vec_dist(pos, target_pos)
			if dist > (mob.width or 1) + 1.5 then
				dinos.action_pursue(mob, player, 2, "dinos:steer", 0.5, "walk")
			else
				creatura.action_idle(mob, 1, "idle")
			end
		end
	end
	self:set_utility(func)
end)

-- Flee Utility
creatura.register_utility("dinos:flee", function(self, target)
	local timeout = 8
	local function func(mob)
		local target_alive, _, target_pos = mob:get_target(target)
		local pos = mob.object:get_pos()
		if not pos or not target_alive or not target_pos then
			mob._puncher = nil
			return true
		end

		local dist = vec_dist(pos, target_pos)
		if dist >= (mob.tracking_range or 16) + 4 then
			mob._puncher = nil
			return true
		end

		if not mob:get_action() then
			local flee_to = vec_add(pos, vec_multi(vec_dir(target_pos, pos), 6))
			dinos.action_walk(mob, 1.0, 1.0, "run", flee_to)
		end

		timeout = timeout - mob.dtime
		if timeout <= 0 then
			mob._puncher = nil
			return true
		end
	end
	self:set_utility(func)
end)

-- Attack / Hunt / Counter-Attack Utility
local function attack_utility(self, target)
	local has_attacked = false
	local function func(mob)
		local target_alive, _, target_pos = mob:get_target(target)
		if not target_alive or not target_pos then
			if mob._target == target then mob._target = nil end
			if mob._puncher == target then mob._puncher = nil end
			return true
		end

		local pos = mob.object:get_pos()
		if not pos then return true end

		local dist = vec_dist(pos, target_pos)
		if dist > (mob.tracking_range or 16) * 1.5 then
			if mob._target == target then mob._target = nil end
			if mob._puncher == target then mob._puncher = nil end
			return true
		end

		if not mob:get_action() then
			if has_attacked then
				return true, 1
			end

			local reach = (mob.width or 1) + 1.5
			if dist > reach then
				dinos.action_pursue(mob, target, 1.0, "dinos:steer", 1.0, "run")
			else
				dinos.action_melee(mob, target)
				has_attacked = true
			end
		end
	end
	self:set_utility(func)
end

creatura.register_utility("dinos:attack", attack_utility)
creatura.register_utility("dinos:hunt", attack_utility)
creatura.register_utility("dinos:counter_attack", attack_utility)

-------------------------------------
-- Reusable Utility Stack Elements --
-------------------------------------

dinos.mob_ai.basic_wander = {
	utility = "dinos:wander",
	step_delay = 0.25,
	get_score = function(self)
		return 0.1, {self}
	end
}

dinos.mob_ai.swim_seek_land = {
	utility = "dinos:swim_seek_land",
	step_delay = 0.25,
	get_score = function(self)
		if self.in_liquid then
			return 0.3, {self}
		end
		return 0
	end
}

dinos.mob_ai.follow_player = {
	utility = "dinos:follow",
	get_score = function(self)
		local player = dinos.get_nearby_player(self)
		if player and self:follow_wielded_item(player) then
			return 0.4, {self, player}
		end
		return 0
	end
}

dinos.mob_ai.flee = {
	utility = "dinos:flee",
	get_score = function(self)
		local puncher = self._puncher
		if puncher and creatura.is_alive(puncher) and puncher:get_pos() then
			return 0.8, {self, puncher}
		end
		self._puncher = nil

		if self.predators then
			local predator = dinos.get_nearby_object(self, self.predators)
			if predator and predator:get_pos() then
				return 0.7, {self, predator}
			end
		end
		return 0
	end
}

dinos.mob_ai.counter_attack = {
	utility = "dinos:counter_attack",
	get_score = function(self)
		local puncher = self._puncher
		if puncher and creatura.is_alive(puncher) then
			local pos = self.object:get_pos()
			local tpos = puncher:get_pos()
			if pos and tpos and vec_dist(pos, tpos) <= (self.tracking_range or 16) * 1.5 then
				return 0.8, {self, puncher}
			end
		end
		self._puncher = nil
		return 0
	end
}

dinos.mob_ai.hunt = {
	utility = "dinos:hunt",
	get_score = function(self)
		local puncher = self._puncher
		if puncher and creatura.is_alive(puncher) and puncher:get_pos() then
			return 0.9, {self, puncher}
		end
		self._puncher = nil

		local target = self._target
		if not (target and creatura.is_alive(target) and target:get_pos()) then
			target = dinos.get_nearby_player(self)
			if target and target:is_player() and minetest.is_creative_enabled(target:get_player_name()) then
				target = nil
			end
			if not target and self.prey then
				target = dinos.get_nearby_object(self, self.prey)
			end
			self._target = target
		end

		if target and target:get_pos() then
			return 0.8, {self, target}
		end
		return 0
	end
}

-------------------------------------
-- Shared Mob Lifecycle Callbacks  --
-------------------------------------

function dinos.activate_func(self)
	self._puncher = nil
	self._target = nil
	if self.animations and self.animations["idle"] then
		self:animate("idle")
	end
end

function dinos.step_func(self)
	-- Refresh nearby objects once per second so AI reacts promptly
	if self:timer(1) then
		self:store_nearby_objects()
	end
	if self._nearby_objs then
		self._nearby_obj = self._nearby_objs
	end

	-- Keep dinosaurs buoyant at water surface so they can wade/swim to shore
	if self.in_liquid then
		local vel = self.object:get_velocity()
		if vel and vel.y < 0.5 then
			self.object:set_velocity({x = vel.x, y = 1.2, z = vel.z})
		end
	end
end

function dinos.death_func(self)
	if self:get_utility() ~= "dinos:die" then
		self:initiate_utility("dinos:die", self)
	end
end

function dinos.on_punch(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
	creatura.basic_punch_func(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
	if puncher and puncher ~= self.object and creatura.is_alive(puncher) then
		self._puncher = puncher
		self._target = puncher
	end
end

function dinos.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then return end
	local item, item_name = self:follow_wielded_item(clicker)
	if item and item_name then
		if self.hp < (self.max_health or 20) then
			self:heal(max(4, floor((self.max_health or 20) * 0.25)))
			self:memorize("hp", self.hp)
		end
		self._puncher = nil
		self._target = nil
		if not minetest.is_creative_enabled(clicker:get_player_name()) then
			item:take_item()
			clicker:set_wielded_item(item)
		end
		local pos = self:get_center_pos() or self.object:get_pos()
		if pos then
			minetest.add_particlespawner({
				amount = 6,
				time = 0.2,
				minpos = {x = pos.x - 0.5, y = pos.y, z = pos.z - 0.5},
				maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
				minvel = {x = -0.5, y = 1, z = -0.5},
				maxvel = {x = 0.5, y = 2, z = 0.5},
				minexptime = 0.6,
				maxexptime = 1.0,
				minsize = 2,
				maxsize = 4,
				texture = "heart.png",
			})
		end
	end
end
