----------------
-- Spawn Eggs --
----------------

local spawn_eggs = {
	apatosaurus = {
		desc = "Apatosaurus Spawn Egg",
		col1 = "646d5e",
		col2 = "8d8068",
	},
	parasaurolophus = {
		desc = "Parasaurolophus Spawn Egg",
		col1 = "7c8574",
		col2 = "c15963",
	},
	stegosaurus = {
		desc = "Stegosaurus Spawn Egg",
		col1 = "857258",
		col2 = "6d5e48",
	},
	trex = {
		desc = "T-Rex Spawn Egg",
		col1 = "656d62",
		col2 = "bfb990",
	},
	triceratops = {
		desc = "Triceratops Spawn Egg",
		col1 = "64646d",
		col2 = "a59581",
	},
	velociraptor = {
		desc = "Velociraptor Spawn Egg",
		col1 = "6d564b",
		col2 = "8d756b",
	},
}

for mob_name, def in pairs(spawn_eggs) do
	local entity_name = "dinos:" .. mob_name
	if creatura.register_spawn_item then
		creatura.register_spawn_item(entity_name, {
			description = def.desc,
			col1 = def.col1,
			col2 = def.col2,
		})
	else
		minetest.register_craftitem("dinos:spawn_" .. mob_name, {
			description = def.desc,
			inventory_image = "(creatura_spawning_crystal_primary.png^[multiply:#" .. def.col1 .. ")^(creatura_spawning_crystal_secondary.png^[multiply:#" .. def.col2 .. ")",
			on_place = function(itemstack, placer, pointed_thing)
				if pointed_thing.type ~= "node" then
					return itemstack
				end
				local under = pointed_thing.under
				local node = minetest.get_node(under)
				local node_def = minetest.registered_nodes[node.name]
				if node_def and node_def.on_rightclick
				and not (placer and placer:is_player() and placer:get_player_control().sneak) then
					return node_def.on_rightclick(under, node, placer, itemstack, pointed_thing) or itemstack
				end
				local pos = minetest.get_pointed_thing_position(pointed_thing, true)
				if not pos then return itemstack end
				if minetest.is_protected(pos, placer and placer:get_player_name() or "") then
					return itemstack
				end
				local mobdef = minetest.registered_entities[entity_name]
				local spawn_offset = (mobdef and mobdef.collisionbox and math.abs(mobdef.collisionbox[2])) or 0
				pos.y = (pos.y - 0.49) + spawn_offset
				local obj = minetest.add_entity(pos, entity_name)
				if obj then
					local yaw = math.random() * math.pi * 2
					obj:set_yaw(yaw)
					local ent = obj:get_luaentity()
					if ent then
						ent.last_yaw = yaw
					end
					if not minetest.is_creative_enabled(placer and placer:get_player_name() or "") then
						itemstack:take_item()
					end
				end
				return itemstack
			end,
		})
	end
end
