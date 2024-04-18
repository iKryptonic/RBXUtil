-- All Items should look like
-- Weapon
	-- Data (Module) *Contains this code
	-- ModelParts (Model) *Contains all the misc parts
	-- Handle (Part) *The part the item is held by

local Meta = {

	-- Weapon Data Start

	-----------------------------------
	------------ Information ----------
	-----------------------------------
	Name		= "Javelin", -- Item Name
	Id			= "4",
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
	StowC1		= CFrame.new(3.56173372, 0.542638421, -0.15500474, 0.766046762, -0.642784297, 0.0007974857, -0.000798218185, -0.00219195802, -0.999997258, 0.642784297, 0.76604414, -0.00219222461);
	-- What is the output data on where we hold this item relative to the StowPart?

	-----------------------------------
	------------ Grip Data ------------
	-----------------------------------
	GripC1		= CFrame.new(0.0126714706, 0.992999077, 0.00506925583, 0.999994159, 2.90325772e-08, -0.00341043272, -2.92071576e-08, 1, -5.11404963e-08, 0.00341043272, 5.12398088e-08, 0.999994159); 
	-- What is the output data on where we hold this item relative to the arm?

	-----------------------------------
	------------ Item Data ------------
	-----------------------------------
	ItemType 	= 'Weapon', -- What kind of item is this?
	WeaponType 	= 'Polearm', -- THIS ONLY MATTERS IF Weapon IS SET TO TRUE! 
	-- What kind of Weapon is this? (Staff, Sword, Polearm, Axe, Wand, Dagger)

	-----------------------------------
	------------ Animations -----------
	-----------------------------------
	Effects      = script:FindFirstChild("Effects");
	Animations = { -- Now we start using IDs for animation keyframes
		Idle = {
			[1] = {"RightKick1", 0, 0.25}, -- Keyframe name, Frame duration
			t 	= 26, -- KeyframeSequence Duration
		}, 

		Combos = {
			[1] = {
				t 	= 50, -- KeyframeSequence Duration
				Type = "Normal",
				{"", 10}, -- Keyframe name, Frame duration
				{"Damage", 11, 25, 0.25, 1, true, .01}, -- DamageFrame, Calculate combo damage here
				-- Event, TimeAt, HitSoundId, Volume, Pitch, DebounceHit, DebounceDelay
				{"", 20}, -- Keyframe
			},
		}, 
	}

}
return Meta;