-----------------
-- Triceratops --
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

creatura.register_mob("dinos:triceratops", {
	-- Stats
	max_health = 70,
	armor_groups = {fleshy = 85},
	damage = 10,
	speed = 4,
	tracking_range = 16,
	despawn_after = 1500,

	-- Physics
	max_fall = 4,
	turn_rate = 4.5,
	stepheight = 1.1,
	bouyancy = 0.25,
	makes_footstep_sound = true,
	hitbox = {
		width = 1.4,
		height = 2.3
	},

	-- Visuals
	mesh = "dinos_triceratops.b3d",
	textures = {"dinos_triceratops.png"},
	visual_size = {x = 1.0, y = 1.0},

	-- Animations (from Blender NLA Strip Builder)
	animations = {
		idle = {range = {x = 1, y = 63}, speed = 24, frame_blend = 0.3, loop = true},
		stand = {range = {x = 1, y = 63}, speed = 24, frame_blend = 0.3, loop = true},
		walk = {range = {x = 71, y = 143}, speed = 24, frame_blend = 0.3, loop = true},
		run = {range = {x = 151, y = 172}, speed = 30, frame_blend = 0.3, loop = true},
		attack = {range = {x = 180, y = 200}, speed = 24, frame_blend = 0.3, loop = false},
		melee = {range = {x = 180, y = 200}, speed = 24, frame_blend = 0.3, loop = false},
		death = {range = {x = 208, y = 252}, speed = 24, frame_blend = 0.3, loop = false},
		jump = {range = {x = 260, y = 302}, speed = 24, frame_blend = 0.3, loop = false},
	},

	-- Behavior Parameters
	follow = follow,
	is_herding_mob = true,
	is_grazing_mob = true,

	-- Drops
	drops = {
		{name = "bonemeal:bone", min = 2, max = 5, chance = 1},
	},

	-- AI Utility Stack (Armored herbivore, charges with horns when provoked)
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

creatura.register_abm_spawn("dinos:triceratops", {
	chance = 6000,
	interval = 60,
	min_light = 10,
	min_height = 1,
	max_height = 200,
	min_group = 1,
	max_group = 3,
	nodes = {"default:dirt_with_grass", "default:dirt_with_rainforest_litter"},
})
