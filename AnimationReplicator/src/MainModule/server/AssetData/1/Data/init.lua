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
	Name		= "Greatsword", -- Item Name
	Id			= "1",
	Weapon		= true, -- Is this a weapon?
	Dual 		= false, -- Are one of these held in each hand?

	WeaponStats = {
		Attack 	= 20; -- How much attack the weapon has
		Defense	= 0; -- How much Defense the weapon has
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
	GripC1		= CFrame.new(1.1920929e-07, 0, 0.999999881, -4.40049917e-08, 0, -0.999999881, -0.99999994, -4.37113847e-08, 4.3772161e-08, -4.37113847e-08, 0.99999994, 3.55271368e-15); 
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
	Effects		= script:FindFirstChild("Effects");
	
	Animations = { -- Now we start using IDs for animation keyframes
		Idle = {
			[1] = {"GreatSwordIdle1", 0, 0.4}, -- Keyframe name, Frame duration, Frame Speed
			[2] = {"GreatSwordIdle2", 30, 0.1}, -- Keyframe name, Frame duration, Frame Speed
			[3] = {"GreatSwordIdle1", 60, 0.05}, -- Keyframe name, Frame duration, Frame Speed
			t 	= 100, -- KeyframeSequence Duration
		},

		Combos = {
			[1] = {
				[1] = {
					[1] = {"DiagonalSlash-001", 8, 0.25}, -- Keyframe name, Frame duration
					[2] = {"Effect", 10, "EmpowerCharacter"}, -- Keyframe Position, Effect Name
					[3] = {"Damage", 13, "935843979", 0.25, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2}, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					-- Event, TimeAt, HitSoundId, Volume, Pitch, DebounceHit, DebounceDelay
					[4] = {"Sound", 13, "486314644", 0.75, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2}, true},
					[5] = {"DiagonalSlash-002", 13, 0.25}, -- Keyframe
					[6] = {"Damage", 15, "935843979", 0.25, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2}, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					[7] = {"DiagonalSlash-003", 18, 0.25}, -- Keyframe
					[8] = {"Damage", 21, "935843979", 0.25, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2}, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					t 	= 27, -- KeyframeSequence Duration
				},
				[2] = {
					[1] = {"DiagonalSlash-010", 8, 0.25}, -- Keyframe name, Frame duration
					[2] = {"Effect", 10, "EmpowerCharacter"}, -- Keyframe Position, Effect Name
					[3] = {"Damage", 13, "935843979", 0.25, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2}, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					-- Event, TimeAt, HitSoundId, Volume, Pitch, DebounceHit, DebounceDelay
					[4] = {"Sound", 13, "486314644", 0.75, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2}, true},
					[5] = {"DiagonalSlash-020", 13, 0.25}, -- Keyframe
					[6] = {"Damage", 15, "935843979", 0.25, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2}, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					[7] = {"DiagonalSlash-030", 18, 0.25}, -- Keyframe
					[8] = {"Damage", 21, "935843979", 0.25, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2}, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					t 	= 27, -- KeyframeSequence Duration
				},
				[3] = {
					[1] = {"Sound", 5, "486314644", 0.75, 1, true},
					[2] = {"Slash-001", 8, 0.25}, -- Keyframe name, Frame duration
					[3] = {"Effect", 10, "EmpowerCharacter"}, -- Keyframe Position, Effect Name
					[4] = {"Damage", 13, "935843979", 0.25, 1, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					-- Event, TimeAt, HitSoundId, Volume, Pitch, DebounceHit, DebounceDelay
					[5] = {"Slash-002", 13, 0.25}, -- Keyframe
					[6] = {"Damage", 15, "935843979", 0.25, 1, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					[7] = {"Slash-003", 18, 0.25}, -- Keyframe
					[8] = {"Damage", 21, "935843979", 0.25, 1, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					[9] = {"Slash-004", 23, 0.25}, -- Keyframe
					[10] = {"Damage", 28, "935843979", 0.25, 1, true, .5, 12}, -- DamageFrame, Calculate combo damage here
					t 	= 33, -- KeyframeSequence Duration
				},
				Type= "Sequential",
			},
			[2] = { -- The Combo
				[1] = {"RightPunch", 13, 0.1},
				[2] = {"LeftPunch", 26, 0.1},
				[1] = {"RightPunch", 33, 0.1},
				t 	= 46, -- KeyframeSequence Duration
				Type= "Normal",
			}
		}, 
	},
}
return Meta;