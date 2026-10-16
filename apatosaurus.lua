-----------------
-- Apatosaurus --
-----------------

local follow = {
	"default:leaves",
	"default:jungleleaves",
	"default:fern_1",
	"default:fern_2",
	"default:fern_3",
	"default:apple",
	"farming:wheat",
	"group:flora",
	"group:leaves",
}

creatura.register_mob("dinos:apatosaurus", {
	-- Stats
	max_health = 100,
	armor_groups = {fleshy = 80},
	damage = 12,
	speed = 3,
	tracking_range = 20,
	despawn_after = 1500,

	-- Physics
	max_fall = 4,
	turn_rate = 3.5,
	stepheight = 1.1,
	bouyancy = 0.25,
	makes_footstep_sound = true,
	hitbox = {
		width = 2.0,
		height = 3.5
	},

	-- Visuals
	mesh = "dinos_apatosaurus.b3d",
	textures = {"dinos_apatosaurus.png"},
	visual_size = {x = 1.0, y = 1.0},

	-- Animations (from Blender NLA Strip Builder)
	animations = {
		idle = {range = {x = 1, y = 104}, speed = 24, frame_blend = 0.3, loop = true},
		stand = {range = {x = 1, y = 104}, speed = 24, frame_blend = 0.3, loop = true},
		walk = {range = {x = 112, y = 238}, speed = 24, frame_blend = 0.3, loop = true},
		run = {range = {x = 247, y = 283}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 292, y = 338}, speed = 24, frame_blend = 0.3, loop = false},
		melee = {range = {x = 292, y = 338}, speed = 24, frame_blend = 0.3, loop = false},
		death = {range = {x = 347, y = 386}, speed = 24, frame_blend = 0.3, loop = false},
		jump = {range = {x = 395, y = 440}, speed = 24, frame_blend = 0.3, loop = false},
	},

	-- Behavior Parameters
	follow = follow,
	is_herding_mob = true,
	is_grazing_mob = true,

	-- Drops
	drops = {
		{name = "bonemeal:bone", min = 3, max = 8, chance = 1},
	},

	-- AI Utility Stack (Peaceful giant herbivore, defends itself if attacked)
	utility_stack = {
		dinos.mob_ai.basic_wander,
		dinos.mob_ai.swim_seek_land,
		dinos.mob_ai.follow_player,
		dinos.mob_ai.counter_attack,
	},

	activate_func = dinos.activate_func,
	step_func = dinos.step_func,
	death_func = dinos.death_func,
	on_punch = dinos.on_punch,
	on_rightclick = dinos.on_rightclick,
})

creatura.register_abm_spawn("dinos:apatosaurus", {
	chance = 8000,
	interval = 60,
	min_light = 10,
	min_height = 1,
	max_height = 200,
	min_group = 1,
	max_group = 2,
	nodes = {"default:dirt_with_grass", "default:dirt_with_rainforest_litter"},
})
