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
	Name		= "Dagger", -- Item Name
	Id			= "2",
	Weapon		= true; -- Is this a weapon?
	Dual 		= true, -- Are one of these held in each hand?

	WeaponStats = {
		Attack = 10; -- How much attack the weapon has
		Defense = 0; -- How much Defense the weapon has
	},

	-----------------------------------
	------------ Stow Data ------------
	-----------------------------------
	Stowable	= false, -- Does this stow to a body part when un-equipped from main-hand?
	StowPartName= "Torso", -- What part does this stow to?
	StowC1		=  CFrame.new(-0.528973937, 1.12346458, -0.778989553, 0.00341120758, -5.82593475e-06, 0.999994159, -0.999994159, -8.34303648e-07, 0.00341120758, 8.1442488e-07, -1, -5.82874873e-06);
	-- What is the output data on where we hold this item relative to the StowPart?

	-----------------------------------
	------------ Grip Data ------------
	-----------------------------------
	GripC1		= CFrame.new(0.0307598114, -0.0423665047, -1.0289917, -0.999994159, -5.90620766e-06, 0.00341120758, -0.00341120758, -8.56510667e-07, -0.999994159, 5.90909576e-06, -1, 8.36358481e-07); 
	-- What is the output data on where we hold this item relative to the arm?

	-----------------------------------
	------------ Item Data ------------
	-----------------------------------
	ItemType 	= 'Weapon', -- What kind of item is this?
	WeaponType 	= 'Dagger', -- THIS ONLY MATTERS IF Weapon IS SET TO TRUE! 
	-- What kind of Weapon is this? (Staff, Sword, Polearm, Axe, Wand, Dagger)
	
	
	
	-----------------------------------
	------------ Effects ------------
	-----------------------------------
	Effects		= script:FindFirstChild("Effects");
	
	
	-----------------------------------
	------------ Animations -----------
	-----------------------------------
	Animations = { -- Now we start using IDs for animation keyframes
		Idle = {
			[1] = {"DaggerIdle-1", 0, 0.15}, -- Keyframe name, Frame duration
			[2] = {"DaggerIdle-2", 30, 0.015}, -- Keyframe name, Frame duration
			[3] = {"DaggerIdle-3", 60, 0.015}, -- Keyframe name, Frame duration
			t 	= 90, -- KeyframeSequence Duration
		}, 

		Combos = {
			[1] = {
				Type = "Sequential",
				[1] = {
					[1] = {"DaggerSlash-1;1", 8,0.25},
					[2] = {"DaggerSlash-1;2", 13,0.4},
					[3] = {"Damage",18,"4681189157",1,{0.8,0.9,1}, true, .1},
					
					t 	= 23, -- KeyframeSequence Duration
				},
				[2] = {
					[1] = {"DaggerSlash-2;1", 8,0.25},
					[2] = {"DaggerSlash-2;2", 13,0.4},
					[3] = {"DaggerSlash-2;3", 18,0.4},
					[4] = {"Effect",19,"Thrust"},
					[5] = {"Damage",23,"4681189157",1,{0.8,0.9,1}, true, .1},

					t 	= 28, -- KeyframeSequence Duration

				},
				[3] = {
					[1] = {"DaggerSlash-3;1", 8,0.25},
					[2] = {"DaggerSlash-3;2", 13,0.4},
					[3] = {"DaggerSlash-3;3", 18,0.4},
					[4] = {"Effect",19,"Thrust"},
					[5] = {"Damage",23,"4681189157",1,{0.8,0.9,1}, true, .1},

					t 	= 28, -- KeyframeSequence Duration

				},
				
				[4] = {
					[1] = {"DaggerSlash-4;1", 10,0.4},
					[2] = {"DaggerSlash-4;2", 15,0.4},
					[3] = {"DaggerSlash-4;3", 20,0.4},
					[4] = {"DaggerSlash-4;4", 25,0.4},
					[5] = {"Damage",30,"4681189157",1,{0.8,0.9,1}, true, .1},

					t 	= 32, -- KeyframeSequence Duration

				},
			},
			[2] = {
				Type = "Normal",
				[1] = {"DaggerE-1",1,0.4},
				[2] = {"Effect",2,"EmpowerCharacter"},
				[3] = {"DaggerE-2",20,0.4},
				[4] = {"Effect",21,"EmpowerCharacter"},
				[5] = {"DaggerE-3",25,0.4},
				[6] = {"Effect",26,"EmpowerCharacter"},
				[7] = {"DaggerE-4",28,0.4},
				[8] = {"Effect",29,"EmpoweredLunge"},
				[9] = {"DaggerE-5",33,0.4},
				[10] = {"Damage",40,"4681189157",1,{0.8,0.9,1}, true, .1},
				t	 = 50,
			},
			[3] = {
				Type = "Normal",
				[1] = {"DaggerR-1",7,0.3},
				[2] = {"Effect",9,"Leap"},
				[3] = {"DaggerR-2",10,0.3},
				[4] = {"DaggerR-3",13,0.3},
				[5] = {"DaggerR-4",16,0.3},
				[6] = {"DaggerR-5",19,0.3},
				[7] = {"DaggerR-6",28,0.3},
				[8] = {"DaggerR-7",31,0.3},
				[9] = {"Damage",33,"4681189157",1,{0.8,0.9,1}, true, .1},
				[10] = {"DaggerR-8",34,0.3},
				[11] = {"DaggerR-9",37,0.3},
				t	 = 50,
			},
			[4] = {
				Type = "Normal",
				[1] = {"DaggerF-1",10,0.3},
				[2] = {"DaggerF-2",20,0.3},
				[3] = {"Damage",23,"4681189157",1,{0.8,0.9,1}, true, .1},
				[4] = {"DaggerF-3",35,0.3},
				[5] = {"DaggerF-4",40,0.3},
				[6] = {"Damage",43,"4681189157",1,{0.8,0.9,1}, true, .1},
				[7] = {"DaggerF-5",45,0.3},
				t	= 50,
			}
		}, 
	}

}
return Meta;