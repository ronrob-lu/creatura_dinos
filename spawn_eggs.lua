-- Dinosaur Spawn Eggs registration for Luanti / Minetest

local dinos_list = {
	{id = "apatosaurus", description = "Apatosaurus Spawn Egg"},
	{id = "parasaurolophus", description = "Parasaurolophus Spawn Egg"},
	{id = "stegosaurus", description = "Stegosaurus Spawn Egg"},
	{id = "trex", description = "T-Rex Spawn Egg"},
	{id = "triceratops", description = "Triceratops Spawn Egg"},
	{id = "velociraptor", description = "Velociraptor Spawn Egg"},
}

local function spawn_dino_at(mob_name, pos, placer)
	local obj = minetest.add_entity(pos, mob_name)
	if obj then
		if placer and placer:is_player() then
			local dir = placer:get_look_dir()
			local yaw = minetest.dir_to_yaw(dir)
			obj:set_yaw(yaw)
		end
		return obj
	end
	return nil
end

for _, dino in ipairs(dinos_list) do
	local mob_name = "dinos:" .. dino.id
	local item_name = "dinos:spawn_egg_" .. dino.id
	local texture_name = "dinos_spawn_egg_" .. dino.id .. ".png"

	minetest.register_craftitem(item_name, {
		description = dino.description,
		inventory_image = texture_name,
		groups = {spawn_egg = 1, dino_spawn_egg = 1},
		on_place = function(itemstack, placer, pointed_thing)
			if not pointed_thing or pointed_thing.type ~= "node" then
				return itemstack
			end

			local pos = minetest.get_pointed_thing_position(pointed_thing, true)
			if not pos then
				return itemstack
			end

			local obj = spawn_dino_at(mob_name, pos, placer)
			if obj then
				local player_name = placer and placer:is_player() and placer:get_player_name()
				if not player_name or not (minetest.is_creative_enabled and minetest.is_creative_enabled(player_name)) then
					itemstack:take_item()
				end
			end
			return itemstack
		end,
	})
end

-- Chat command to easily spawn dinos for debugging
minetest.register_chatcommand("spawn_dino", {
	params = "<dino_name>",
	description = "Spawns a dinosaur at your position (apatosaurus, parasaurolophus, stegosaurus, trex, triceratops, velociraptor)",
	privs = {give = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end
		param = param:lower():match("^%s*(.-)%s*$")
		if param == "" then
			return false, "Specify dinosaur name: apatosaurus, parasaurolophus, stegosaurus, trex, triceratops, velociraptor"
		end
		local mob_name = "dinos:" .. param
		if not minetest.registered_entities[mob_name] then
			return false, "Unknown dinosaur mob: " .. mob_name
		end
		local pos = player:get_pos()
		local dir = player:get_look_dir()
		pos.x = pos.x + dir.x * 2
		pos.z = pos.z + dir.z * 2
		local obj = spawn_dino_at(mob_name, pos, player)
		if obj then
			return true, "Spawned " .. param .. "!"
		else
			return false, "Failed to spawn " .. param
		end
	end,
})
