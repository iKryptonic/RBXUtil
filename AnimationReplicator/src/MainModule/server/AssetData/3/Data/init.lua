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
	Name		= "Hammer", -- Item Name
	Id			= "3",
	Weapon		= true, -- Is this a weapon?
	Dual 		= false, -- Are one of these held in each hand?

	WeaponStats = {
		Attack = 0; -- How much attack the weapon has
		Defense = 0; -- How much Defense the weapon has
	},

	-----------------------------------
	------------ Stow Data ------------
	-----------------------------------
	Stowable	= false, -- Does this stow to a body part when un-equipped from main-hand?
	StowPartName= "Torso", -- What part does this stow to?
	StowC1		= CFrame.new(3.56173372, 0.542638421, -0.15500474, 0.766046762, -0.642784297, 0.0007974857, -0.000798218185, -0.00219195802, -0.999997258, 0.642784297, 0.76604414, -0.00219222461);
	-- What is the output data on where we hold this item relative to the StowPart?

	-----------------------------------
	------------ Grip Data ------------
	-----------------------------------
	GripC1 		= CFrame.new(1.08772671, 0.0353505611, 0.471961975, 8.18789481e-16, 1, 8.62591195e-16, -1.72518239e-15, 8.62591248e-16, -0.99999994, -0.99999994, -8.18789481e-16, -1.72518239e-15), 
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
			[1] = {"HammerIdle-1", 0, 0.1}, -- Keyframe name, Frame duration
			[2] = {"HammerIdle-2", 30, 0.1}, -- Keyframe name, Frame duration
			[3] = {"HammerIdle-3", 60, 0.1}, -- Keyframe name, Frame duration
			[4] = {"HammerIdle-1", 90, 0.05}, -- Keyframe name, Frame duration
			t 	= 120, -- KeyframeSequence Duration
		}, 

		Combos = {
			[1] = {
				{"", 10}, -- Keyframe name, Frame duration
				{"Damage", 11, 25, 0.25, 1, true, .01}, -- DamageFrame, Calculate combo damage here
				-- Event, TimeAt, HitSoundId, Volume, Pitch, DebounceHit, DebounceDelay
				{"", 20}, -- Keyframe
				Type = "Normal",
				t 	= 50, -- KeyframeSequence Duration
			},
		}, 
	}

}
return Meta;