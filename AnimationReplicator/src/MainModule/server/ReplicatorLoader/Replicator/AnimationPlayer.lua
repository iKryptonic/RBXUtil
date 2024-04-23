-- @Name: 	AnimationPlayer.lua
-- @Author: iKrypto
-- @Date: 	10/10/2020

--[[
API:
	AnimationPlayer.new(Player player) - Creates a new AnimationPlayer Object
	
	- Properties [read-only]
		Status - AnimationPlayer's status
		ClassName - The ClassName of the object
		Player - The current player of the AnimationPlayer
		Animating - Whether or not an animation is currently playing
		Name - The name of the object
		Iterator - The iterating number value of the animator (Used for sine/cosine operations within the animation table)
		LeftArmInUse - Boolean for if the arm is holding an object from the inventory
		RightArmInUse - Boolean for if the arm is holding an object from the inventory
		
	- Methods
		-- Fetches the current state of the replicator (-1 = dead, 0 = stopped, 1 = running)
		AnimationPlayer::	getState
							GetState
						@Constructor
							AnimationPlayer:GetState()
						@Returns Integer number
		
		-- Fetches the main player subject of the replicator
		AnimationPlayer::	getPlayer
							GetPlayer
						@Constructor
							AnimationPlayer:GetPlayer()
						@Returns Player player
		
		-- Fetches the main player's character
		AnimationPlayer::	getCharacter
							GetCharacter
						@Constructor
							AnimationPlayer:GetCharacter()
						@Returns Model character
		
		-- Finds whether or not the replicator's character exists
		AnimationPlayer::	hasCharacter
							HasCharacter
						@Constructor
							AnimationPlayer:HasCharacter()
						@Returns Boolean true/false
		
		-- Kills the replicator and prevents it executing any animations
		AnimationPlayer::	destroy
							Destroy
							remove
							Remove
							stop
							Stop
						@Constructor
							AnimationPlayer:Destroy()
						@Returns nil
		
		-- Loads a set of animations from a table format (found under examples)
		AnimationPlayer::	loadAnimationSetFromTable
							LoadAnimationSetFromTable
						@Constructor
							AnimationPlayer:loadAnimationSetFromTable(Table AnimationTable)
						@Returns nil
								
		-- Plays a custom animation from the loaded set of animations
		AnimationPlayer::	PlayAnimationCustom
							playAnimationCustom
						@Constructor
							AnimationPlayer:PlayAnimationCustom(String AnimationName, Integer Speed)
						@Returns nil
								
		-- Plays a custom animation from a table (able to be affected by AnimationPlayer.Iterator)
		AnimationPlayer::	PlayAnimationByTable
							PlayAnimationByTable
						@Constructor
							AnimationPlayer:PlayAnimationByTable(String AnimationName, Table ReferenceTable, Integer Speed)
						@Returns nil
								
		-- Starts the AnimationPlayer's main functions
		AnimationPlayer::	Initialize
							initialize
						@Constructor
							AnimationPlayer:Initialize()
						@Returns nil
]]

-- TODO: 
-- Override specific joints based on animation priority
-- R15 Support

-- 2 V3 vals for Position/Rotation use multiplicative expressions to compile to final cframe solution

repeat wait() until (shared.SecureFn~=nil)

local AnimationPlayer = {};

-- Setting up service provider
local Services = setmetatable({}, {__index=function(self, index)return game:GetService(index); end;})

-- The LocalPlayer variable
local Owner = Services.Players.LocalPlayer

-- Grabbing network for character effects
local Network = shared.SecureFn(Owner, "jK3`u*.a2P)H7Q66bT2%u7%]e`3EQ=Qy|HGop@JK53w35AC1a4Q")[2];

-- Determining Script type
local ScriptType = (Services.RunService:IsClient() and 'Client' or 'Server')

-- This creates a "AnimationPlayer" object

function AnimationPlayer.new(Player)
	assert(typeof(Player)=="Instance", ("bad argument #1 to 'Player' (Player expected, got %s)"):format(typeof(Player))) -- Thanks Mokiros
	assert(Player:IsA('Player'), ("bad argument #1 to 'Player' (Player expected, got %s)"):format(Player.ClassName))

	local obj 		= newproxy(true)-- Create object for the AnimationPlayer metatable
	local Methods 	= {}; -- The tables methods which can be triggered by Table. or Table()
	local Properties= {}; -- The properties of the table which are only accessible via Table.
	
	do -- Create object metadata
		local obj_meta 	= getmetatable(obj) -- Cannot use setmetatable() on objects because they are userdata, we must getmetatable() on the newproxy() first

		obj_meta.__index=function(self, index)
			if Methods[index] then
				return Methods[index]; -- First look for a method
			elseif Properties[index] then
				return Properties[index]; -- Alternatively look for a property
			end;
			return nil; -- Else, exit and return nil
		end;
		obj_meta.__newindex=function(self)
			error("This object is readonly.", 0); -- Prevent addition of new keys to table
			return nil;
		end;
		obj_meta.__call=function(self, method, ...)
			if Methods[method] then
				return Methods[method](self, ...) -- Allow for Table(Method, Argument) calls for method invocation
			end;
			return nil;
		end;
		obj_meta.__tostring="AnimationPlayer"; -- Override the tostring() behaviour of the table
		obj_meta.__metatable="This metatable is locked."; -- Lock the newproxy's metatable
	end;


	-- Establish initial properties of the object
	Properties.Iterator = 1; -- Infinitely iterating variable for animation runtime
	Properties.Status = "stopped"; -- AnimationPlayer's status
	Properties.ClassName = "AnimationPlayer"; -- The ClassName of the object
	Properties.Player = Player; -- The current player of the AnimationPlayer
	Properties.Animating = false; -- Whether or not an animation is currently playing
	Properties.Name = "AnimationPlayer"; -- The name of the object
	Properties.LeftArmInUse = false; -- Whether or not the left arm is animating
	Properties.RightArmInUse = false; -- Whether or not the right arm is animating

	-- Setting up destroy with a few aliases
	local function Destroy()
		Properties.Status = "ended"; -- Set the AnimationPlayer to ended to prevent any actions for executing (besides getState)
		Properties.Player = nil; -- Clear the player property of the now defunct AnimationPlayer
	end;

	-- Alias setting
	rawset(Methods, "destroy", Destroy)
	rawset(Methods, "Destroy", Destroy)
	rawset(Methods, "remove", Destroy)
	rawset(Methods, "Remove", Destroy)
	rawset(Methods, "stop", Destroy)
	rawset(Methods, "Stop", Destroy)
	-- End Alias Setting

	-- Setting up Getter Methods
	-- Returns the object's current state
	local function GetState()
		local States = {
			["stopped"] = 0; -- stopped: 	Not initialized
			["running"] = 1; -- running: 	Currently animating a character
			["ended"]	= -1;-- ended:		Has been stopped permanently
		}
		return States[Properties.Status];
	end

	-- Returns the player object of the AnimationPlayer
	local function GetPlayer()
		return Player;
	end
	-- Returns a boolean determining if the character exists
	local function HasCharacter()
		return (Player.Character and true or false);
	end
	-- Returns the character object of the AnimationPlayer
	local function GetCharacter()
		return Player.Character;
	end

	-- Alias setting
	rawset(Methods, "getState", GetPlayer)
	rawset(Methods, "GetState", GetPlayer)
	rawset(Methods, "getPlayer", GetPlayer)
	rawset(Methods, "GetPlayer", GetPlayer)
	rawset(Methods, "hasCharacter", GetPlayer)
	rawset(Methods, "HasCharacter", GetPlayer)
	rawset(Methods, "getCharacter", GetPlayer)
	rawset(Methods, "GetCharacter", GetPlayer)
	-- End Alias Setting


	---------------------------------------- BEGINNING OF ANIMATION METHODS -------------------------------------------------
	local AnimationsInternal = {};
	local CurrentAnimation = "";
	local CurrentTrack = {
		Animation = {};
		Priority = 1;	
	};

	local DefaultAnimations = {
		["Running"] = {};
		["Idle"] = {};
		["Jumping"] = {};
		["FreeFalling"] = {};
	};

	local SetUpConnection; -- Dynamic RBXScriptSignal

	-- Character set-up Methods

	local Character, LeftArm, RightArm, LeftLeg, RightLeg, Head, Torso, RootPart, RootJoint, Humanoid, RootCF, NeckCF, RW, LW, RH, LH, RHW, LHW
	local cfn = CFrame.new
	local cfa = CFrame.Angles
	local mr = math.rad

	-- Returns the current playing animation
	local function GetPlayingTrack()
		return {CurrentAnimation, CurrentTrack.Priority};
	end

	-- Sets functions variables according to a pre-made character
	local function SetUp(NewCharacter)
		if (GetState()==-1) then error("This object has ended.", 0) return end
		if (not NewCharacter:findFirstChild("CreateAnimator")) then
			repeat wait() until (NewCharacter:findFirstChild'CreateAnimator' or (not NewCharacter.Parent))
		end

		if (not NewCharacter.Parent) then
			warn("No character parent")
			return
		end

		-- Set-up default character (Before I make any armor or anything)
		local Create = function(Ins)
			return function(Table)
				local Object = Instance.new(Ins);
				for i,v in next,Table do
					Object[i]=v;
				end;
				return Object;
			end;
		end;

		Character = NewCharacter;

		Humanoid = Character:WaitForChild("Humanoid")

		if (not Humanoid) then
			warn("No Humanoid Found")
			return
		end

		if (Humanoid.RigType~=Enum.HumanoidRigType.R6) then 
			warn("R15 is not supported.") 
			return 
		end

		LeftArm = Character:WaitForChild("Left Arm")
		RightArm = Character:WaitForChild("Right Arm")
		LeftLeg = Character:WaitForChild("Left Leg")
		RightLeg = Character:WaitForChild("Right Leg")
		Head = Character:WaitForChild("Head")
		Torso = Character:WaitForChild("Torso")
		RootPart = Character:WaitForChild("HumanoidRootPart")
		RootJoint = RootPart:WaitForChild("RootJoint")

		pcall(function()		
			Humanoid.Animator.Parent = nil
			Character.Animate.Parent = nil
		end)

		local function NewMotor(part0, part1, c0, c1)
			local w = Create("Motor")({
				Parent = part0,
				Part0 = part0,
				Part1 = part1,
				C0 = c0,
				C1 = c1
			})
			return w
		end

		RootCF = cfa(-1.57, 0, 3.14)
		NeckCF = cfn(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
		RW = NewMotor(Torso, RightArm, cfn(1.5, 0, 0), cfn(0, 0, 0))
		LW = NewMotor(Torso, LeftArm, cfn(-1.5, 0, 0), cfn(0, 0, 0))
		RH = NewMotor(Torso, RightLeg, cfn(0.5, -2, 0), cfn(0, 0, 0))
		LH = NewMotor(Torso, LeftLeg, cfn(-0.5, -2, 0), cfn(0, 0, 0))
		RootJoint.C1 = cfn(0, 0, 0)
		RootJoint.C0 = cfn(0, 0, 0)
		Torso.Neck.C1 = cfn(0, 0, 0)
		Torso.Neck.C0 = cfn(0, 1.5, 0)
	end;

	-- JSONEncoding tables for remote events
	local function Encode(self, Table)
		return Services.HttpService:JSONEncode(Table);
	end
	-- JSONDecoding tables for remote events
	local function Decode(self, Table)
		return Services.HttpService:JSONDecode(Table);
	end

	-- Internal function
	-- Used for playing animations to the character from a reference table
	local function PlayAnimationFromTable(ReferenceTable, Speed, Modifier)
		if (GetState()==-1) then error("This object has ended.", 0) return end
		if (not Humanoid) or (Humanoid.Health <= 0) then return end

		-- Negligible delay with this method
		local function clerp(a, b, t)
			return a:lerp(b, t) -- Not using Quaternion nonsense because there is no need for it when this works just as well.
		end

		-- Surely there's a better way to do this, COME BACK

		RootJoint.C1 = clerp(RootJoint.C1, cfn(unpack(ReferenceTable[1])) * (Modifier and (cfn(Modifier[1][1], Modifier[1][2], Modifier[1][3]) * cfa(Modifier[1][4], Modifier[1][5], Modifier[1][6])) or cfn()), Speed) -- Set RootJoint weld
		Torso.Neck.C1 = clerp(Torso.Neck.C1, cfn(unpack(ReferenceTable[2])) * (Modifier and (cfn(Modifier[2][1], Modifier[2][2], Modifier[2][3]) * cfa(Modifier[2][4], Modifier[2][5], Modifier[2][6])) or cfn()), Speed) -- Set Neck weld
		RW.C1 = clerp(RW.C1, cfn(unpack(ReferenceTable[3])) * (Modifier and (cfn(Modifier[3][1], Modifier[3][2], Modifier[3][3]) * cfa(Modifier[3][4], Modifier[3][5], Modifier[3][6])) or cfn()), Speed) -- Set Right Arm weld
		LW.C1 = clerp(LW.C1, cfn(unpack(ReferenceTable[4])) * (Modifier and (cfn(Modifier[4][1], Modifier[4][2], Modifier[4][3]) * cfa(Modifier[4][4], Modifier[4][5], Modifier[4][6])) or cfn()), Speed) -- Set Left Arm weld
		RH.C1 = clerp(RH.C1, cfn(unpack(ReferenceTable[5])) * (Modifier and (cfn(Modifier[5][1], Modifier[5][2], Modifier[5][3]) * cfa(Modifier[5][4], Modifier[5][5], Modifier[5][6])) or cfn()), Speed) -- Set Right Leg weld
		LH.C1 = clerp(LH.C1, cfn(unpack(ReferenceTable[6])) * (Modifier and (cfn(Modifier[6][1], Modifier[6][2], Modifier[6][3]) * cfa(Modifier[6][4], Modifier[6][5], Modifier[6][6])) or cfn()), Speed) -- Set Left Leg weld
		if (ReferenceTable[7]~=nil) and (RHW~=nil) then
			RHW.C0 = clerp(RHW.C0, cfn(unpack(ReferenceTable[7])) * (Modifier and (cfn(Modifier[7][1], Modifier[7][2], Modifier[7][3]) * cfa(Modifier[7][4], Modifier[7][5], Modifier[7][6])) or cfn()), Speed) -- Set Right Handle weld
		end	
		if (ReferenceTable[8]~=nil) and (LHW~=nil) then
			LHW.C0 = clerp(LHW.C0, cfn(unpack(ReferenceTable[8])) * (Modifier and (cfn(Modifier[8][1], Modifier[8][2], Modifier[8][3]) * cfa(Modifier[8][4], Modifier[8][5], Modifier[8][6])) or cfn()), Speed) -- Set Left Handle weld
		end
	end

	-- Batch loading animation profiles
	local function LoadAnimationSetFromTable(self, AnimationTable)
		if (GetState()==-1) then error("This object has ended.", 0) return end
		if typeof(AnimationTable)=="string" then AnimationTable = Decode(self, AnimationTable) end
		-- Type checking
		assert(typeof(AnimationTable)=="table", ("bad argument #1 to 'AnimationStructure' (table expected, got %s)"):format(typeof(AnimationTable)))

		if typeof(AnimationTable)=='table' then
			for animationName, animTable in next, AnimationTable do
				AnimationsInternal[animationName] = animTable; -- Load all the animations internally
			end;
		end;
	end;

	-- Alias setting
	rawset(Methods, "loadAnimationSetFromTable", LoadAnimationSetFromTable)
	rawset(Methods, "LoadAnimationSetFromTable", LoadAnimationSetFromTable)
	-- End Alias setting

	-- Play a Custom Animation
	local function PlayAnimationCustom(self, AnimationName, Speed)
		if (GetState()==-1) then error("This object has ended.", 0) return end
		if AnimationsInternal[AnimationName] then
			local AnimationTrack = AnimationsInternal[AnimationName];

			if (AnimationTrack.Priority >= CurrentTrack.Priority) then
				CurrentTrack = {
					Reference = AnimationTrack.Reference, 
					Priority = AnimationTrack.Priority,
				}
				CurrentAnimation = AnimationName;

				PlayAnimationFromTable(AnimationTrack.Reference, Speed, (AnimationTrack.Modifier and AnimationTrack.Modifier or nil))
			else
				warn(("Priority mismatch for %s (%d) and %s (%d)"):format(CurrentAnimation, CurrentAnimation.Priority, AnimationName, AnimationTrack.Priority))
			end;
		else
			warn(("Animation %s not found "):format(AnimationName))
		end
	end

	-- Alias setting
	rawset(Methods, "PlayAnimationCustom", PlayAnimationCustom)
	rawset(Methods, "playAnimationCustom", PlayAnimationCustom)
	-- End Alias setting

	-- Play Animation from table
	local function PlayAnimationByTable(self, AnimationName, ReferenceTable, Speed)
		if typeof(ReferenceTable)=="string" then ReferenceTable = Decode(self, ReferenceTable) end

		local Priority = ReferenceTable.Priority

		if (Priority >= CurrentTrack.Priority) then
			CurrentTrack = {
				Reference = ReferenceTable.Reference,
				Priority = ReferenceTable.Priority,
			}
			CurrentAnimation = AnimationName

			PlayAnimationFromTable(ReferenceTable.Reference, Speed, (ReferenceTable.Modifier and ReferenceTable.Modifier or nil))
		else
			warn(("Priority mismatch for %s (%d) and %s (%d)"):format(CurrentAnimation, CurrentTrack.Priority, AnimationName, Priority))
		end
	end

	-- Alias setting
	rawset(Methods, "PlayAnimationByTable", PlayAnimationByTable)
	rawset(Methods, "playAnimationByTable", PlayAnimationByTable)
	-- End Alias setting

	local function Initialize(self)
		if GetState()~=0 then error("This object has already been initialized!", 0) return end

		repeat wait() until Player.Character

		rawset(Properties, 'Status', 'running')
		SetUp(Player.Character)
		SetUpConnection = Player.CharacterAdded:Connect(SetUp)

		-------------------------------- NETWORK LISTENER ------------------------------
		Network:Listen('ChangeEquip', function(Origin, EquipStatus, Arm, Item, HandleWeld)
			if Origin==Player then
				if Arm.Name=='Right Arm' then
					if EquipStatus=='UnEquip' then
						RHW = nil;
						rawset(Properties, 'RightArmInUse', false)
					elseif EquipStatus=='Equip' then
						RHW = HandleWeld
						rawset(Properties, 'RightArmInUse', true)
					end
				elseif Arm.Name=='Left Arm' then
					if EquipStatus=='UnEquip' then
						LHW = nil;
						rawset(Properties, 'LeftArmInUse', false)
					elseif EquipStatus=='Equip' then
						LHW = HandleWeld
						rawset(Properties, 'LeftArmInUse', true)
					end
				end
			end
		end)

		-- Beginning animation iterator
		coroutine.wrap(function()
			local waitEvent = ((ScriptType=='Client') and Services.RunService.RenderStepped or Services.RunService.Heartbeat)
			local i = 0;

			while waitEvent:wait() do
				if (GetState()==-1) then break end;
				i=(i+.03);
				rawset(Properties, 'Iterator', i);
			end;
			rawset(Properties, 'Iterator', 0);
		end)()
	end

	-- Alias setting
	rawset(Methods, "Initialize", Initialize)
	rawset(Methods, "initialize", Initialize)
	-- End Alias setting
	return obj
end


return AnimationPlayer;