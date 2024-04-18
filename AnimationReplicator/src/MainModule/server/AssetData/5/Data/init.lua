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
	Name		= "Staff", -- Item Name
	Id			= "5",
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
	StowC1		= CFrame.new(0.571868539, -0.259943962, -0.114463329, -0.00341043272, -5.12397875e-08, -0.999994159, 0.707102656, 0.707106769, -0.00241157622, 0.707102656, -0.707106769, -0.00241150404);
	-- What is the output data on where we hold this item relative to the StowPart?

	-----------------------------------
	------------ Grip Data ------------
	-----------------------------------
	GripC1		= CFrame.new(-1.09299278, -0.0167622566, -0.0203533173, 2.92070865e-08, -1, 5.11404892e-08, -0.00341043272, -5.12398159e-08, -0.999994159, 0.999994159, 2.90326483e-08, -0.00341043272); 
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