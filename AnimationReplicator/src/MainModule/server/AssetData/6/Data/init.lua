local Meta = {

	-- Weapon Data Start

	-----------------------------------
	------------ Information ----------
	-----------------------------------
	Name		= "Claymore", -- Item Name
	Id			= "6",
	Weapon		= true, -- Is this a weapon?
	Dual 		= false, -- Are one of these held in each hand?

	WeaponStats = {
		Attack = 0; -- How much attack the weapon has
		Defense = 0; -- How much Defense the weapon has
	},

	-----------------------------------
	------------ Stow Data ------------
	-----------------------------------
	Stowable	= true, -- Does this stow to a body part when un-equipped from main-hand?
	StowPartName= "Torso", -- What part does this stow to?
	StowC1		= CFrame.new(-0.536045432, 4.19162178, 0.110815048, 0.00341588678, -5.08069752e-06, 0.999994159, -0.766039252, -0.642788291, 0.0026134674, 0.642784536, -0.766043723, -0.00219957577);
	-- What is the output data on where we hold this item relative to the StowPart?

	-----------------------------------
	------------ Grip Data ------------
	-----------------------------------
	GripC1		= CFrame.new(0.048573494, 0.041190505, -1.03467119, -0.999994159, -7.46412798e-06, 0.00341132027, -0.00341132097, -1.04895332e-06, -0.999994159, 7.46764408e-06, -1, 1.02397587e-06);
	-- What is the output data on where we hold this item relative to the arm?

	-----------------------------------
	------------ Item Data ------------
	-----------------------------------
	ItemType 	= 'Weapon', -- What kind of item is this?
	WeaponType 	= 'Sword', -- THIS ONLY MATTERS IF Weapon IS SET TO TRUE! 
	-- What kind of Weapon is this? (Staff, Sword, Polearm, Axe, Wand, Dagger)

	-----------------------------------
	------------ Animations -----------
	-----------------------------------
	Effects      = script:FindFirstChild("Effects");
	Animations = { -- Now we start using IDs for animation keyframes
		Idle = {
			[1] = {"ClaymoreIdle-1", 0, 0.15}, -- Keyframe name, Frame duration
			[2] = {"ClaymoreIdle-2", 30, 0.015}, -- Keyframe name, Frame duration
			[3] = {"ClaymoreIdle-3", 60, 0.015}, -- Keyframe name, Frame duration
			[4] = {"ClaymoreIdle-4", 90, 0.015}, -- Keyframe name, Frame duration
			t 	= 120, -- KeyframeSequence Duration
		}, 

		Combos = {
			[1] = {
				{"ClaymoreLS-1", 8, 0.25},
				{"ClaymoreLS-2", 16, 0.25},
				{"ClaymoreLS-3", 25, 0.25},
				Type = "Normal",
				t 	= 27, -- KeyframeSequence Duration
			},
			[2] = {
				{"ClaymoreBunt-1", 8, 0.25},
				{"ClaymoreBunt-2", 16, 0.25},
				{"ClaymoreBunt-3", 25, 0.25},
				Type = "Normal",
				t 	= 27, -- KeyframeSequence Duration
			},
			[3] = {
				{"ClaymoreLSv2-1", 8, 0.25},
				{"ClaymoreLSv2-2", 16, 0.25},
				{"ClaymoreLSv2-3", 25, 0.25},
				Type = "Normal",
				t 	= 27, -- KeyframeSequence Duration
			},
		}, 
	}

}
return Meta;