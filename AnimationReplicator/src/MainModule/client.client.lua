--@Name:	Client.lua
--@Author:	iKrypto
--@Date:	10/10/2020
--[[
	-- @Changelog
		(10/29/20)
			+ Switched code over to use KeyFrame animation style
			+ Added some utilities for playing audios
			- Removed lightning (This is only the beginner class)
--]]

--[[
	-- @Bugs/Issues:
		* Can attack when dead
		* Animations dont load on players who join after you
	
]]

--[[
	- TODO: 
	
		- Do a Sprite Replicator (For a pet-like thing)
		
		- Implement CC detection for client (will also be enforced on server)
		
		- Do the GUIs
			- Circular menu with options
				- Inventory
				- Controls
				- Help
			- Party 
			- Character Status (Damaged *Green/Yellow/Orange/Red*)
			- Character UI Frame
				- Health
				- Level
				- Mana
				- Stamina
		
		- Begin Server-side work of the script
			- Buff handling
			- Party Handling
			- CCing
			
		- Begin coding magic and casting
			Long casts / Short casts 
		
		- Code stats for players
			- HP (Max Health)
			- MP (Spell Casting)
			- SP (Stamina / Movement)
		
]]

repeat wait() until (shared.SecureFn~=nil);

-- Setting up service provider
local Services 	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;})
local keyCodes 	= setmetatable({}, {__index=function(self, index)local keyCode = Enum.KeyCode[index]; return keyCode; end;})

--[==[
NS([[local Init = Instance.new("Model")
Init.Name = 'CreateAnimator'
Init.Parent = workspace:findFirstChild("]]..Services.Players.LocalPlayer.Name..[[")
]], workspace)--]==]

wait(1.5)

-- Key Bindings
local KeyStrokeKey 	= keyCodes.C; -- The key to be used with keystrokes

local AttackOneKey 	= keyCodes.Q; -- Key for Attack 1
local AttackTwoKey 	= keyCodes.E; -- Key for Attack 2
local AttackThreeKey= keyCodes.R; -- Key for Attack 3
local AttackFourKey	= keyCodes.F; -- Key for Attack 4

local BlockKey		= keyCodes.LeftControl -- Key for Debounces.Blocking
local SprintKey		= keyCodes.LeftAlt -- Sprint key
local ToggleWeapon	= keyCodes.Z; -- Weapon to toggle the stowed/unstowed primary weapon

local MenuKey		= keyCodes.M; -- Menu Key (Interface)

local JUMP_COOLDOWN	= 1; -- Limit jumping to once every x seconds
local MELEE_HIT_RANGE = 5 -- Range in studs for a proper hit

---------------------- * COMBOS ARE MANAGED IN Ctrl+F -> "- COMBOS -" area of the script






---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------> HEY! THE MAIN SCRIPT FUNCTIONS <-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------> ARE ALL DEFINED IN THE BELOW   <-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------> CODE. DON'T MESS WITH WHAT YOU <-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------> DONT UNDERSTAND PLEASE. THANKS <-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Determining Input Types
local IS_CONSOLE= Services.GuiService:IsTenFootInterface()
local IS_MOBILE = Services.UserInputService.TouchEnabled and not Services.UserInputService.MouseEnabled and not IS_CONSOLE

-- Common Services
local Players			= Services.Players;
local UIS				= Services.UserInputService;
local Lighting			= Services.Lighting;
local ReplicatedStorage	= Services.ReplicatedStorage;
local CollectionS		= Services.CollectionService

-- Getting Player & PlayerData & Saving assets
local Player 	= Players.LocalPlayer;
local Camera	= workspace.CurrentCamera;
local Assets	= ReplicatedStorage:WaitForChild("Assets", 10):Clone()
local Animations= require(Assets:WaitForChild("Animations"))

-- Setting Character Values
local Character = Player.Character;
local Head 		= Character:WaitForChild("Head");
local Torso 	= Character:WaitForChild("Torso");
local RightArm 	= Character:WaitForChild("Right Arm");
local LeftArm	= Character:WaitForChild("Left Arm");
local RightLeg 	= Character:WaitForChild("Right Leg");
local LeftLeg 	= Character:WaitForChild("Left Leg");
local RootPart 	= Character:WaitForChild("HumanoidRootPart");
local Humanoid 	= Character:WaitForChild("Humanoid");

-- Modules
-- Get the animation replicator from shared
-- The replicator object that sends effect/animation data
local DATA		= shared.SecureFn(Player, "jK3`u*.a2P)H7Q66bT2%u7%]e`3EQ=Qy|HGop@JK53w35AC1a4Q");
local Replicator= DATA[1];
local Network	= DATA[2];
local Controls 	= DATA[3];

-- Shortcuts
local V3 		= Vector3.new
local CF 		= CFrame.new
local CFA		= CFrame.Angles
local MR 		= math.rad
local MRand		= math.random
local Ins 		= Instance.new -- Ideally, this is not used from the client script.
local sin		= math.sin
local cos		= math.cos
local tr		= table.remove
local ti		= table.insert
local mh		= math.huge
local bigVector	= V3(mh, mh, mh)

-- Constants
local Status 			= "Idle" -- The current animation cycle

local CurrentSpeed 		= 0 -- General Movement speed
local vSpeed 			= 0 -- Vertical Speed
local AnimSpeed			= 1 -- The speed at which animations move
local DesiredWalkSpeed	= 16 -- WalkSpeed we'd ideally like to be, but it's ok if we don't reach it.
local Movement			= 0 -- Dynamic variable to determine snaring.
local inQueue			= 0 -- Used in task scheduler
local KeyFramePosition 	= 0; -- Used for keyframing default animations

local PlayerData		= nil; -- Table to hold the playerdata stored on server
local Connections		= {}; -- RBXScriptSignals to be disconnected on script end
local Anim 				= {} -- Placeholder.
local Combos 			= {} -- Keystroke stuffs 
local Tasks				= {} -- Task Scheduler
local AssetCache		= {} -- Caching for asset data retrieval
local Debounces = {
	CanAnimate 	= true, -- Whether or not custom animations are running
	Blocking 	= false, -- Blocking attacks or not
	Stunned		= false, -- If the player is Stunned
	Knocked		= false, -- If the player has been knocked down
	MouseLocked	= true, -- Controls the player facing their camera direction
	DoubleJump	= false, -- If double jump is available
	CanMovement	= true, -- If movement keys can be used
	WeaponEqp	= false, -- If a weapon is equipped
	ItemEqp		= {}, -- Whether or not a weapon is equipped
	Damaged		= {}, -- The models we have hit and are debouncing
	Sequences	= {}, -- The ComboSequences being handled by weapons
	LastStatus	= "", -- Debouncing weapon keyframes
}

local CurrentEquip		= nil;
local AnimationSignal 	= nil; -- Used for keyframes.
local Animator			= nil; -- The player's animator

-- Setting up script tables
local Input 			= {};
local Util 				= {};
local Attacks 			= {};
local CharacterMovers 	= {};
local BodyParts 		= {};
local KeyFunctions 		= {};
local MainLoop;

-- Stepped Wait
local SWait = function()
	return Services.RunService.Stepped:wait();
end

-------------------------------- Character Movers -------------------------------------
do
	local MoverList = {};

	local Get = function(MoverName)
		return MoverList[MoverName];
	end;

	local EnableMover = function(MoverName, F)
		local Mover = Get(MoverName);
		if Mover then
			if Mover:isA'BodyGyro' or Mover:isA'BodyAngularVelocity' then
				Mover.MaxTorque = F;
			else
				Mover.MaxForce = F;
			end;
		end;
		return Mover;
	end;

	local DisableMover = function(MoverName)
		local Mover = Get(MoverName);
		if Mover then
			if Mover:isA'BodyGyro' or Mover:isA'BodyAngularVelocity' then
				Mover.MaxTorque = V3();
			else
				Mover.MaxForce = V3();
			end;
		end;
		return Mover;
	end;

	local NewMover = function(MoverName, MoverObject)
		local Obj = Ins(MoverObject);
		MoverList[MoverName] = Obj;
		DisableMover(MoverName)

		return Obj;
	end;

	-- Create the rotational stance gyro
	local StanceGyro = NewMover("StanceGyro", "BodyGyro")
	StanceGyro.P = 10000
	StanceGyro.D = 200
	StanceGyro.Parent = RootPart

	-- Set methods
	CharacterMovers.Get = Get
	CharacterMovers.get = Get
	CharacterMovers.DisableMover = DisableMover
	CharacterMovers.disableMover = DisableMover
	CharacterMovers.EnableMover = EnableMover
	CharacterMovers.enableMover = EnableMover
	CharacterMovers.NewMover = NewMover
	CharacterMovers.newMover = NewMover
end

------------------------------- SCRIPT FUNCTIONS --------------------------------------
do
	-- Shoot a vanilla raycast
	local RayCast = function(Position, Direction, Range, Ignore) -- Update this to use WorldRoot:Raycast
		return workspace:FindPartOnRay(Ray.new(Position, Direction.unit * (Range or 999.999)), Ignore)
	end

	-- Find the ground under the character
	local FindGround = function()
		return RayCast(RootPart.Position, CF(RootPart.Position, RootPart.Position - V3(0, 1, 0)).lookVector, 4, Character)
	end

	-- Camera Shaking
	local ShakeCam = function(Intensity, waitingTime)
		Camera.CFrame = Camera.CFrame * CF(0, (Intensity or 2), 0)
		wait(waitingTime or 1/30)
		Camera.CFrame = Camera.CFrame * CF(0, (Intensity and -Intensity or -2), 0)
	end

	-- Get the normal of the character's position and cframe
	local CharacterPlane = function()
		local cf = RootPart.CFrame.lookVector
		return V3(cf.x, 0, cf.z).unit
	end

	-- Check and cancel running animations
	local StopCustoms = function()
		if (AnimationSignal) then
			AnimationSignal:disconnect();
			AnimationSignal = nil;
		end
		return true;
	end

	-- Get the forward facing direction of the camera
	local FaceCameraForwardDirection = function()
		if not Character then return{CF(0,0,0),CF(0,0,0)}end
		return{CF(RootPart.Position,V3(Camera.CFrame.x,RootPart.Position.y,Camera.CFrame.z)) * CFrame.fromEulerAnglesXYZ(0,math.pi,0),V3(Camera.CFrame.p.x,RootPart.CFrame.p.y,Camera.CFrame.p.z)}
	end

	-- Gets forward direction based on mouse
	local FaceMouseForwardDirection = function()
		local AimCF = CF(RootPart.Position, Input.Mouse:GetHitCFrame().p)
		local AimingDirection = AimCF.lookVector
		local headingA = math.atan2(AimingDirection.x, AimingDirection.z)

		return CF(RootPart.Position) * CFA(MR(0), MR(headingA - 180), MR(0))
	end

	-- Cast the forward hit-detection cone
	local ScanMeleeRange = function(DebounceCheck, DebounceDuration, Radius)
		local function CheckIfInBox(VictimRoot)
			local Point = RootPart.CFrame:PointToObjectSpace(VictimRoot.Position)
			local Distance = (VictimRoot.Position-RootPart.Position).magnitude
			local Radius = (Radius and Radius or MELEE_HIT_RANGE)
			
			if Point.Z < -0.25 then
				if Distance < Radius then
					return true
				end
			end
			return false
		end
		local function CheckIfKillable(Model)
			local Human = Model:findFirstChild('Humanoid')
			if Human then
				if Human~=Humanoid then
					if Human:isA'Humanoid' then
						if Human.Health > 0 then -- Do checks here
							if Model:findFirstChild('HumanoidRootPart') then
								for _, Part in ipairs(Model:GetChildren()) do
									if Part:IsA("BasePart") then
										if CheckIfInBox(Part) then
											return Model
										end
									end
								end
							end
						end
					end
				end
			end
			return
		end

		local Killable = {};

		for _, Model in ipairs(workspace:GetChildren()) do
			local Victim = CheckIfKillable(Model)

			if Victim then
				if DebounceCheck then
					if Debounces.Damaged[Victim] == true then
						continue
					else
						Debounces.Damaged[Victim] = true;
						Util.Schedule(function() Debounces.Damaged[Victim] = nil end, DebounceDuration)
					end
				end
				table.insert(Killable, Victim)
			end
		end
		return Killable;
	end

	-- Play a custom keyframe animation
	local PlayKeyframe = function(keyFrameFunction, frameLimit, Yielding)
		if (not Debounces.CanAnimate) then return end;

		-- Stop any running keyframes

		local currentFrameReal = 0;

		StopCustoms();

		local KeyframeFinished = false;

		Debounces.CanAnimate = false;

		AnimationSignal=Services.RunService.Stepped:Connect(function()
			currentFrameReal = currentFrameReal + 1; -- Iterate up by 1 frame because we stepped.
			keyFrameFunction(currentFrameReal); -- Run the desired keyframe function on the next frame.

			if (currentFrameReal >= frameLimit) then
				StopCustoms();
				Debounces.CanAnimate = true;
				KeyframeFinished = true;
			end

		end)
		
		Connections[#Connections+1] = AnimationSignal;
		if Yielding then
			repeat SWait() until KeyframeFinished
		end

	end

	-- Run a stun animation on the character
	local DoStun = function(Duration)
		Debounces.MouseLocked = false;
		Debounces.Stunned = true;

		DesiredWalkSpeed = 0;
		local StanceGyro = CharacterMovers.get("StanceGyro")
		StanceGyro.cframe = CF(RootPart.Position, RootPart.Position + CharacterPlane() * 5)

		wait(Duration)
		DesiredWalkSpeed = 16;
		Debounces.Stunned = false;
		Debounces.MouseLocked = true;
	end

	local Schedule = function(Task, TaskDelay, Recurring)
		TaskDelay = (TaskDelay and TaskDelay or 0)
		if Recurring then -- Schedule the task to automatically resume on the same terms
			local TaskOld = Task;
			Task = function()
				coroutine.wrap(Util.Schedule)(Task, TaskDelay)
				TaskOld();
			end;
		end
		inQueue = inQueue + 1
		ti(Tasks, {TIME_REMAINING=TaskDelay, TaskFunction=Task})
		return true
	end


	-- Plays an animation track
	local PlayCustomTrack = function (Name, Speed, DelayNext, FnOnLoop, ...)
		if (not Debounces.CanAnimate) then return end; -- we're already playing a custom animation.

		Debounces.CanAnimate = false;

		for i = 0, 3, Speed do
			-- Set the animation to be played
			Util.PlayAnimationFrame(Name, Speed)

			-- Run a function during the loop, (Rootpart Movement and such.)
			if FnOnLoop then
				FnOnLoop(...);
			end
			SWait();
		end;

		if (DelayNext) then
			wait(DelayNext)
		end

		Debounces.CanAnimate = true;
	end

	-- Get Asset Data for item manipulation
	local AssetData = function(ID)
		if AssetCache[ID] then return AssetCache[ID] end
		local Item = Assets:FindFirstChild(ID, true)
		if Item then
			local ItemData = require(Item:FindFirstChild("Data", true))
			if ItemData then
				local Item_new = newproxy(true)
				local item_meta = getmetatable(Item_new)
				local Properties = {};
				item_meta.__index = function(self, index)
					if Properties[index] then
						return Properties[index]
					else
						return ItemData[index]
					end
				end
				item_meta.__newindex=function(self)
					error("This is a read-only object.", 0);
				end
				item_meta.__metatable="locked"

				AssetCache[ID] = Item_new;
				return Util.AssetData(ID)
			else
				warn(("[AssetData]: Asset retrieval for %s failed!"):format(ID))
			end
		else
			warn(("[AssetData]: Asset retrieval for %s failed!"):format(ID))
		end
		return
	end;

	-- Makes the character move in a certain direction
	local MakeImpulse = function(Direction, Amount)

		local Impulse = Ins("BodyVelocity")

		local Vel = V3();
		local MF = V3();

		if Direction=="Forward" then
			Vel = RootPart.CFrame.lookVector * Amount
			MF = V3(mh, 0, mh)
		elseif (Direction=="Backward") then
			Vel = RootPart.CFrame.lookVector * -Amount
			MF = V3(mh, 0, mh)
		elseif (Direction=="Right") then
			Vel = RootPart.CFrame.RightVector * Amount
			MF = V3(mh, 0, mh)
		elseif (Direction=="Left") then
			Vel = RootPart.CFrame.RightVector * -Amount
			MF = V3(mh, 0, mh)
		elseif (Direction=="Up") then
			Vel = RootPart.CFrame.UpVector * Amount
			MF = V3(0, mh, 0)
		elseif (Direction=="Down") then
			Vel = RootPart.CFrame.UpVector * -Amount
			MF = V3(0, mh, 0)
		end

		Impulse.MaxForce = MF;
		Impulse.Velocity = Vel;
		Impulse.Parent = RootPart

		Services.Debris:AddItem(Impulse, 0.01)
	end

	-- Load Animations from Weapon
	local WeaponAnimation = function(ComboID)
		if (not PlayerData) then return end 
		if (Debounces.WeaponEqp==false) then return end
		if (not Debounces.CanAnimate) then return end;
		if (not Animator) then return end;

		local Animations = CurrentEquip.Animations;

		if Animations then
			local Combos = Animations.Combos

			if Combos then
				local Combo = Combos[ComboID] -- 1, 2, 3, 4
				
				if Combo then
					local ComboType = Combo.Type
					local KeyFrameLength;
					if ComboType=='Sequential' then
						local SequenceId = CurrentEquip.Name..ComboID..CurrentEquip.Id -- Unique ID for the sequence
						local ComboDebounce = Debounces.Sequences[SequenceId] -- The debounce of the sequence
						-- Maybe add timing out here 
						if (not ComboDebounce) then -- Create the debounce if it doesn't exist
							Debounces.Sequences[SequenceId] = {SequenceLength=#Combo, Pointer=0, LastRun=tick()}
						end
						local SeqTable = Debounces.Sequences[SequenceId]
						
						SeqTable.Pointer = SeqTable.Pointer + 1;
						
						if (SeqTable.Pointer > SeqTable.SequenceLength) or (tick()-SeqTable.LastRun > 1) then
							SeqTable.Pointer  = 1;
						end
						SeqTable.LastRun = tick();
						Combo = Combo[SeqTable.Pointer]
					end

					KeyFrameLength = Combo.t
					
					local SoundDebounced = {};
					
					Util.PlayKeyframe(function(f)
						local AnimationPlayed = false;
					
						for index, ComboKeyFrame in ipairs(Combo) do
							if (not AnimationPlayed) then
								local Animation = ComboKeyFrame[1] -- Get the animation name
								local AnimationTimeAt = ComboKeyFrame[2] -- Get the condition for playing the keyframe

								if f <= AnimationTimeAt then -- If we haven't already played a keyframe on this frame
									if Animation=='Damage' then -- Check if we should be dealing damage on this frame
										local SoundId = ComboKeyFrame[3]; -- Hit SoundId
										local Volume = ComboKeyFrame[4]; -- Hit Sound Volume
										local Pitch = ComboKeyFrame[5]; -- Hit Sound Pitch
										local Debounce = ComboKeyFrame[6]; -- Boolean for Debouncing Hit
										local DebounceDelay = ComboKeyFrame[7]; -- Delay before toggling debounce to false
										local RadiusChange = ComboKeyFrame[8]; -- Radius check change for melee damage (Longer blades = higher)
										
										local Hit = Util.ScanMeleeRange(Debounce, DebounceDelay, RadiusChange) -- Grab players in melee range
										for _, Victim in pairs(Hit) do -- Iterate the players
											Util.DoDamage(Victim, CurrentEquip.WeaponStats.Attack, "WeaponDamage") -- Send damage to the server based on tool's function
											if ComboKeyFrame[3] then -- Check if a SoundId was specified
												Util.PlaySound(Head, SoundId, Volume, Pitch) -- Optionally play a sound
											end
										end
									elseif Animation=='Sound' then
										-- Sound Data 
										local SoundId = ComboKeyFrame[3];
										local Volume = ComboKeyFrame[4];
										local Pitch = ComboKeyFrame[5];
										local SoundDeb = ComboKeyFrame[6];
										
										if SoundDeb then
											if (not SoundDebounced[SoundId..CurrentEquip.Name]) then
												SoundDebounced[SoundId..CurrentEquip.Name] = true;
												-- Play Sound
												Util.PlaySound(Head, SoundId, Volume, Pitch)
											end
										else
											Util.PlaySound(Head, SoundId, Volume, Pitch) -- Optionally play a sound
										end
									elseif Animation=='Effect' then
										local DesiredEffect = ComboKeyFrame[3];
										local WeaponEffect = require(CurrentEquip.Effects)(DesiredEffect)
										if WeaponEffect then
											WeaponEffect(Player, Character, Network, Replicator, Util)
										end
									else
										local Speed = ComboKeyFrame[3] -- Get the speed at which we lerp to the keyframe
										-- Debounce playing anymore animations on this frame
										AnimationPlayed = true;
										-- Play the animations for this frame
										Util.PlayAnimationFrame(Animation, Speed) -- Play the frame at the designated position
									end
								end
							end
						end
					end, KeyFrameLength)
				end
				
			end
		end
	end;

	-- Faces the character in a forward direction
	local FaceForward = function(UseCamera)
		CharacterMovers.get("StanceGyro").cframe = (UseCamera and FaceCameraForwardDirection()[1] or FaceMouseForwardDirection())
		return CharacterMovers.get("StanceGyro")
	end

	-- Play a custom Animation frame
	local PlayAnimationFrame = function(AnimationName, Speed)
		local Animation = Animations[AnimationName]
		if Animation then
			Replicator:FireEvent("Animation", "PlayAnimationByTable", AnimationName, Replicator:Encode{ -- Play animations directly
				Reference = Animation.Reference;
				Modifier = Animation.Modifier;
				Priority = Animation.Priority;
			}, Speed)
		end
	end

	-- Damage a player
	local DoDamage = function(Model, Damage, AttackName)
		Network:FireEvent("Damage", Model, Damage, AttackName);
	end;

	-- Play a sound
	local PlaySound = function(Parent, SoundId, Volume, Pitch, ...)
		if (Pitch and typeof(Pitch)=='table') then
			Pitch = Pitch[MRand(1, #Pitch)]
		end
		if (Volume and typeof(Volume)=='table') then
			Volume = Volume[MRand(1, #Volume)]
		end
		if (SoundId and typeof(SoundId)=='table') then
			SoundId = SoundId[MRand(1, #SoundId)]
		end -- pick a random from an array for me pls <3

		Replicator:FireEvent("Sound", Parent, SoundId, Volume, Pitch, ...)
	end

	-- Set Methods
	Util.Schedule			= Schedule;
	Util.schedule			= Schedule;
	Util.MakeImpulse 		= MakeImpulse;
	Util.makeImpulse 		= MakeImpulse;
	Util.PlayCustomTrack	= PlayCustomTrack;
	Util.playCustomTrack	= PlayCustomTrack;
	Util.FaceForward		= FaceForward;
	Util.faceForward		= FaceForward;
	Util.FindGround 		= FindGround;
	Util.findGround 		= FindGround;
	Util.RayCast 			= RayCast;
	Util.rayCast 			= RayCast;
	Util.CharacterPlane		= CharacterPlane;
	Util.characterPlane		= CharacterPlane;
	Util.DoStun				= DoStun;
	Util.doStun				= DoStun;
	Util.PlayKeyframe		= PlayKeyframe;
	Util.playKeyframe		= PlayKeyframe;
	Util.StopCustoms		= StopCustoms;
	Util.stopCustoms		= StopCustoms;
	Util.ScanMeleeRange		= ScanMeleeRange;
	Util.scanMeleeRange		= ScanMeleeRange;
	Util.PlayAnimationFrame	= PlayAnimationFrame;
	Util.playAnimationFrame = PlayAnimationFrame;
	Util.DoDamage			= DoDamage;
	Util.DoDamage			= DoDamage;
	Util.PlaySound			= PlaySound;
	Util.playSound			= PlaySound;
	Util.AssetData			= AssetData;
	Util.assetData			= AssetData;
	Util.WeaponAnimation	= WeaponAnimation;
	Util.weaponAnimation	= WeaponAnimation;
end

-------------------------------- ATTACKS ---------------------------------------
do

	local playCustomTrack 	= Util.PlayCustomTrack
	local PlayAnimationFrame= Util.PlayAnimationFrame

	-- Shortcut function for character movement
	local function forwardImpulse(amount)
		Util.makeImpulse("Forward", (amount and amount or 20))
	end

	-- Some nice lil sound funcs to neaten code
	local function playHit(Parent)
		Util.PlaySound(Parent, "169380525", 0.35, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2})
	end

	local function playWoosh(Parent)
		Util.PlaySound(Parent, "206083107", 0.35, {0.8, 0.85, 0.9, 0.95, 1, 1.05, 1.1, 1.2})
	end

	local function Punch()
		-- Punch Combo
		Util.PlayKeyframe(function(f)

			if f==1 or f==13 then
				playWoosh(f==10 and RightLeg or LeftLeg)
			end

			if f==10 or f==23 then -- Damage frames
				local Hit = Util.ScanMeleeRange() -- get all players in melee hit range
				for _, Victim in pairs(Hit) do 
					Util.DoDamage(Victim, 5, "Punch")
					playHit(f==10 and RightLeg or LeftLeg)
				end
			end

			if (f < 13) then
				PlayAnimationFrame("RightPunch", 0.5)
				forwardImpulse(5)
			else
				PlayAnimationFrame("LeftPunch", 0.5)
				forwardImpulse(5)
			end
		end, 26)
		SWait()
	end

	local function Knee()
		-- Knee
		Util.PlayKeyframe(function(f)
			if (f==14) then
				playWoosh(LeftLeg)
			end

			if (f < 13) then
				PlayAnimationFrame("LeftKnee1", 0.25)

			else
				if f>20 then -- Damage frames
					local Hit = Util.ScanMeleeRange(true, 0.5)
					for _, Victim in pairs(Hit) do 
						Util.DoDamage(Victim, 12, "Knee")
						playHit(LeftLeg)
					end
				end
				PlayAnimationFrame("LeftKnee2", 0.5)
				forwardImpulse(10)
			end
		end, 30)
	end

	local function UpperCut()
		-- Uppercut
		Util.PlayKeyframe(function(f)
			if (f==16) then
				playWoosh(RightArm)
			end
			if (f < 13) then
				PlayAnimationFrame("Uppercut1", 0.25)
				forwardImpulse(15)
			else
				if f>16 then -- Damage frames
					local Hit = Util.ScanMeleeRange(true, 0.5)
					for _, Victim in pairs(Hit) do 
						Util.DoDamage(Victim, 15, "UpperCut")
						playHit(RightArm)
					end
				end
				PlayAnimationFrame("Uppercut2", 0.5)
				Util.makeImpulse("Up", 5)
			end
		end, 30)
	end

	local currentKick = 0;
	local function Kick()
		-- RightLegKick / LeftLegKick
		if (currentKick == 0) then
			Util.PlayKeyframe(function(f)
				if (f==16) then
					playWoosh(RightLeg)
				end
				if (f < 13) then
					PlayAnimationFrame("RightKick1", 0.25)
					forwardImpulse(-10)
				else
					if f>16 then -- Damage frames
						local Hit = Util.ScanMeleeRange(true, 0.5)
						for _, Victim in pairs(Hit) do 
							Util.DoDamage(Victim, 9, "Kick")
							playHit(RightLeg)
						end
					end
					PlayAnimationFrame("RightKick2", 0.5)
					forwardImpulse(20)
				end
			end, 30)
			currentKick = 1;
		else
			Util.PlayKeyframe(function(f)
				if (f==1) then
					playWoosh(LeftLeg)
				end
				if f==10 then -- Damage frames
					local Hit = Util.ScanMeleeRange(true, 0.5)
					for _, Victim in pairs(Hit) do 
						Util.DoDamage(Victim, 9, "Kick")
						playHit(LeftLeg)
					end
				end

				PlayAnimationFrame("LeftKick", 0.25)
				forwardImpulse()
			end, 13)
			currentKick = 0;
		end
	end

	local AttackOne = function()
		if (not Debounces.CanAnimate) then return end; -- we're already playing a custom animation.
		
		if (Debounces.WeaponEqp==true) then
			Util.WeaponAnimation(1)
		else
			while Input:isDown(AttackOneKey) do
				Punch()
			end

			Util.StopCustoms()
			Debounces.CanAnimate = true;
		end
	end

	local AttackTwo = function()
		if (not Debounces.CanAnimate) then return end; 
		
		if (Debounces.WeaponEqp==true) then
			Util.WeaponAnimation(2)
		else
			Knee()
		end
	end

	local AttackThree = function()
		if (not Debounces.CanAnimate) then return end; 
		
		if (Debounces.WeaponEqp==true) then
			Util.WeaponAnimation(3)
		else
			UpperCut()
		end
	end

	local AttackFour = function()
		if (not Debounces.CanAnimate) then return end; 
		
		if (Debounces.WeaponEqp==true) then
			Util.WeaponAnimation(4)
		else
			Kick()
		end
	end

	-- Set Methods
	Attacks.AttackOne 	= AttackOne;
	Attacks.AttackTwo 	= AttackTwo;
	Attacks.AttackThree = AttackThree;
	Attacks.AttackFour 	= AttackFour;
end

-------------------------------- KeyFunctions --------------------------------
do
	local Block = function()
		if (not Debounces.CanAnimate) then return end; 
		while Input:isDown(BlockKey) and (Debounces.CanAnimate==true) do
			Debounces.Blocking = true;
			DesiredWalkSpeed = 0;
			SWait();
		end
		DesiredWalkSpeed = 16
		Debounces.Blocking = false;
	end

	local Sprint = function() -- Sprinting = true/false
		while Input:isDown(SprintKey) do
			DesiredWalkSpeed = 25;
			SWait();
		end
		DesiredWalkSpeed = 16;
	end

	local ToggleWeapon = function()
		if (not PlayerData) then return end 
		if (Debounces.WeaponEqp==true) then
			Debounces.WeaponEqp = false;
			CurrentEquip		= nil;
			Network:FireEvent("ChangeEquip", "UnEquip", RightArm)
			Network:FireEvent("ChangeEquip", "UnEquip", LeftArm)
			return;
		end;

		if (not Debounces.CanAnimate) then return end;
		if (not Animator) then return end;

		local WeaponId = PlayerData.WeaponEqp;

		if WeaponId then
			local WeaponData = Util.AssetData(WeaponId)

			if WeaponData.ItemType=='Weapon' then 

				Debounces.WeaponEqp = true;
				CurrentEquip = WeaponData;

				SWait();
				Network:FireEvent("ChangeEquip", "Equip", WeaponId, RightArm)

				if WeaponData.Dual == true then -- Equip it in both arms
					SWait();
					Network:FireEvent("ChangeEquip", "Equip", WeaponId, LeftArm)
				end
			end
		end
	end

	KeyFunctions.ToggleWeapon	= ToggleWeapon
	KeyFunctions.Sprint 		= Sprint
	KeyFunctions.Block 			= Block
end

-------------------------------- Input ---------------------------------------
do
	-- Control Input Methods
	local Keyboard	= Controls.Keyboard; -- Keyboard Util
	local Mouse		= Controls.Mouse; -- Mouse Util

	-- Movement Keys
	local MovementKeys = {"W", "A", "S", "D", "Space"};

	-- Keystroke magiks
	local KeyStrokeArray = {};
	local Pointer = 1;
	local KeyStrokeMode = false;

	-- Key Connections
	local Connections = {};

	-- Normal Key presses
	local keyBindings = { -- The keys and their associated functions
		[AttackOneKey.Name] 	= Attacks.AttackOne;
		[AttackTwoKey.Name] 	= Attacks.AttackTwo;
		[AttackThreeKey.Name]	= Attacks.AttackThree;
		[AttackFourKey.Name] 	= Attacks.AttackFour;
		[BlockKey.Name] 		= KeyFunctions.Block;
		[SprintKey.Name]		= KeyFunctions.Sprint;
		[ToggleWeapon.Name]		= KeyFunctions.ToggleWeapon;
		--[[
		-- Implement these	
		[MenuKey.Name]		
		--]]
	}

	local ResetKeystrokes = function()
		Pointer = 0;
		KeyStrokeArray = {};
		KeyStrokeMode = false;
	end;

	local newKey = function(KeyName)
		if (Pointer > 5) then
			ResetKeystrokes();
		end;
		KeyStrokeArray[Pointer] = KeyName;

		if (Pointer > 0) then
			-- Concatenate the table to a string
			local tableString = table.concat(KeyStrokeArray);

			-- Iterate all the available combination 
			for Combo, ComboFunction in pairs(Combos) do
				if tableString:find(Combo) then
					ResetKeystrokes();
					ComboFunction();
				end
			end
		end
		Pointer = Pointer + 1
	end;

	local lastMovementKeyData = {Key=nil; Time=nil;}

	-- When a key is pressed
	local KeyDown = function(KeyCode)
		if (Humanoid.Health <= 0) then return end
		local keyAlias = KeyCode.Name 
		if (not (KeyCode == KeyStrokeKey)) then -- Debounce the keystroke key
			if (KeyStrokeMode==true) then
				if (Pointer ~= 0) then
					newKey(keyAlias); -- Index a new keystroke keybinding
				end
			else
				if (keyBindings[keyAlias]) then
					keyBindings[keyAlias]() -- Run the normal keybind
				end
				if (table.find(MovementKeys, keyAlias) ~= nil) then
					if (lastMovementKeyData.Key==keyAlias) then
						if (tick()-lastMovementKeyData.Time) <= 0.4 then
							if (Debounces.CanMovement == true) then
								Debounces.CanMovement = false;
								Util.Schedule(function() Debounces.CanMovement = true end, 0.75)

								if (keyAlias=="W") then
									Util.PlaySound(RootPart, "541909814", 0.5)
									Util.playCustomTrack("Dashing", 0.25, nil, function() Util.MakeImpulse("Forward", 75) end)
								elseif (keyAlias=="A") then
									Util.PlaySound(RootPart, "541909814", 0.5)
									Util.playCustomTrack("DashLeft", 0.25, nil, function() Util.MakeImpulse("Left", 75) end)
								elseif (keyAlias=="S") then
									Util.PlaySound(RootPart, "541909814", 0.5)
									Util.playCustomTrack("DashEnd", 0.25, nil, function() Util.MakeImpulse("Backward", 75) end)
								elseif (keyAlias=="D") then
									Util.PlaySound(RootPart, "541909814", 0.5)
									Util.playCustomTrack("DashRight", 0.25, nil, function() Util.MakeImpulse("Right", 75) end)
								elseif (keyAlias=="Space") and (not Debounces.DoubleJump) and (Debounces.CanAnimate==true) then -- Double Jump
									Util.PlaySound(RootPart, "541909814", 0.5)
									Debounces.DoubleJump = true;

									local StanceGyro = CharacterMovers.Get("StanceGyro");
									local Up = RootPart.CFrame.UpVector;

									spawn(function()
										Util.playCustomTrack("FrontFlip", 0.1, 0.15, function() RootPart.Velocity = Up * 35 end)
									end)

									Debounces.MouseLocked = false;
									StanceGyro.Parent = Torso;

									StanceGyro.CFrame = RootPart.CFrame; -- Reset the CFrame of the stance gyro
									StanceGyro.P = 99960
									for i = 0, 360, 30 do
										StanceGyro.CFrame = StanceGyro.CFrame * CFrame.Angles(-MR(30), 0, 0)
										wait()
									end
									StanceGyro.Parent = RootPart;
									StanceGyro.P = 10000
									Debounces.MouseLocked = true;

								end
							end
						end
					end
					lastMovementKeyData.Time = tick();
					lastMovementKeyData.Key = keyAlias
				end
			end
		else
			if KeyStrokeMode then -- If keystrokes are running..
				ResetKeystrokes(); -- Exit keystroke mode
			else
				KeyStrokeMode = true; -- Enter Keystroke Mode
				Pointer = 1;
				delay(1.75, function()
					if (KeyStrokeMode==true) then
						ResetKeystrokes();
					end
				end)
			end
		end
	end

	-- Disconnect the keydown tracker
	local Disconnect = function()
		for index, RBXScriptSignal in ipairs(Connections) do
			local signal = Connections[index];
			if signal then
				Connections:disconnect();
				Connections[index] = nil;
			end
		end
	end

	local Connect = function()
		Connections[#Connections+1] = Keyboard.KeyDown:connect(KeyDown)
	end

	-- Set Methods
	Input.Mouse		= Mouse;
	Input.isDown	= Keyboard.isDown;
	Input.IsDown	= Keyboard.isDown;
	Input.Connect 	= Connect;
	Input.connect 	= Connect;
	Input.Disconnect= Disconnect;
	Input.disconnect= Disconnect;
end

-------------------------------- HumanoidState ---------------------------------
do

	local handled = false;

	Humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Landed then
			if Debounces.DoubleJump and (not handled) then
				handled = true;
				Util.PlaySound(RootPart, "1248511833", 0.35, .9)

				Debounces.MouseLocked = false;
				CharacterMovers.get("StanceGyro").P = 0
				Util.playCustomTrack("SummonGroundCast", 0.25, 0.05)	
				CharacterMovers.get("StanceGyro").P = 10000					
				Debounces.MouseLocked = true;

				Util.Schedule(function()
					Debounces.DoubleJump = false
					handled = false;
				end, JUMP_COOLDOWN)
			end
		end
	end)
end

-------------------------------- CollectionService ---------------------------------
do
	
	local Callbacks = {
		["OnHit"] = function(Object)
			if (not Debounces.Blocking) then
				-- Our humanoid has been hit
				Util.PlayKeyframe(function(f)
					Util.PlayAnimationFrame("OnHit", 0.5)
					Util.MakeImpulse("Backward", 10)
					DesiredWalkSpeed = 0;
				end, 10, true);
				
				DesiredWalkSpeed = 16;
			end;
		end;
	};
	
	-- Connect to collectionservice
	for CallbackName, CallbackFunction in pairs(Callbacks) do
		Network:listen(CallbackName, CallbackFunction)
	end -- Disconnect these when the client ends.
end

-------------------------------- COMBOS ----------------------------------------
-- Keystroke stuffs
do
	local function NewCombo(KeystrokeSequence, ComboFunction)
		assert(#KeystrokeSequence <= 5, ("KeystrokeSequence out of bounds. (Length mismatch for %s [%d characters])"):format(KeystrokeSequence, #KeystrokeSequence))
		for cName in next, Combos do -- Avoid overwriting combos with already made combos
			if (cName:find(KeystrokeSequence) or KeystrokeSequence:find(cName)) then
				warn(("Combo (%s) intersection conflict with Combo (%s)"):format(KeystrokeSequence, cName))
				return
			end
		end
		Combos[KeystrokeSequence] = ComboFunction;
	end;

	NewCombo("DDQ", 
		function()
			if (not Debounces.CanAnimate) then return end

			local function BigDash()
				local Stance = CharacterMovers.Get("StanceGyro");
				if Stance then

					Stance.P = 1000;

					Util.PlayKeyframe(function(f)

						if (f < 15) then
							Util.PlayAnimationFrame("DashStart", 0.25)
							DesiredWalkSpeed = 0;
						elseif (f < 40) then
							Util.PlayAnimationFrame("Dashing", 0.25)
							Util.MakeImpulse("Forward", 200)
						else
							Util.PlayAnimationFrame("DashEnd", 0.25)
							Util.MakeImpulse("Forward", 75)
						end
					end, 70, true) -- yield this playkeyframe

					DesiredWalkSpeed = 16;
					Stance.P = 10000;

				end
			end

			BigDash()
		end
	)

end

-------------------------------- CHARACTER EFFECTS -----------------------------
--[[
do
	for _, v in pairs(Character:GetChildren()) do
		if v:IsA("Part") then
			ti(BodyParts, v)
		end
	end

	local Bounding = {}
	for _, v in pairs(BodyParts) do
		local temp = {X=nil, Y=nil, Z=nil}
		temp.X = v.Size.X/2 * 10
		temp.Y = v.Size.Y/2 * 10
		temp.Z = v.Size.Z/2 * 10
		Bounding[v.Name] = temp
	end

	function emitLightning()
		local Body1 = BodyParts[MRand(#BodyParts)]
		local Body2 = BodyParts[MRand(#BodyParts)]
		local Pos1 = V3(
			MRand(-Bounding[Body1.Name].X, Bounding[Body1.Name].X)/10,
			MRand(-Bounding[Body1.Name].Y, Bounding[Body1.Name].Y)/10,
			MRand(-Bounding[Body1.Name].Z, Bounding[Body1.Name].Z)/10
		)
		local Pos2 = V3(
			MRand(-Bounding[Body2.Name].X, Bounding[Body2.Name].X)/10,
			MRand(-Bounding[Body2.Name].Y, Bounding[Body2.Name].Y)/10,
			MRand(-Bounding[Body2.Name].Z, Bounding[Body2.Name].Z)/10
		)
		local SPos1 = Body1.Position + Pos1
		local SPos2 = Body2.Position + Pos2

		Replicator:FireEvent("Effect", "Lightning", SPos1, SPos2, 4, 2, 'New Yeller', 0.15, 0.4, 0.05)
	end

	spawn(function()
		while wait(MRand()) do
			emitLightning()
		end
	end)

end
--]]

-------------------------------- MAIN LOOP -------------------------------------
-- Start the Replicator Listener
do
	-- Grab the animator of the current user (This keeps animation frames in sync across clients)
	Animator = Replicator:GetAnimator(Player.userId);

	-- Utility function aliases
	local rayCast 	= Util.RayCast;
	local findGround= Util.FindGround

	-- The function we'll connect to Stepped
	MainLoop = function(dt)
		if (not Animator) then Animator = Replicator:GetAnimator(Player.userId); end

		if (Animator.RightArmInUse) then
			Debounces.ItemEqp['Right'] = true;
		else
			Debounces.ItemEqp['Right'] = false;
		end

		if (Animator.LeftArmInUse) then
			Debounces.ItemEqp['Left'] = true;
		else
			Debounces.ItemEqp['Left'] = false;
		end

		local Vel = RootPart.Velocity;-- Upwards velocity of the torso
		local Iterator = Animator.Iterator-- Constantly iterating variable from AnimationReplicator
		local Speed = (RootPart.Velocity * V3(1, 0, 1))-- Setting a speed variable as our forward magnitude

		-- Footplanting
		local leftLegOriginalCF = (Torso.CFrame*CF(-0.5, -2, 0))
		local rightLegOriginalCF = (Torso.CFrame*CF(0.5, -2, 0))
		local AnglePR = (rightLegOriginalCF-rightLegOriginalCF.p):inverse()*Speed/100 -- Invert the new cframes depending on velocity
		local AnglePL = (leftLegOriginalCF-leftLegOriginalCF.p):inverse()*Speed/100
		local thetaR = (rightLegOriginalCF-rightLegOriginalCF.p):vectorToObjectSpace(Speed/100)-- Put the (now tilted) cframes back to their original cfs
		local thetaL = (leftLegOriginalCF-leftLegOriginalCF.p):vectorToObjectSpace(Speed/100)

		-- Character lookAt
		if (Debounces.MouseLocked) then
			if CharacterMovers.get("StanceGyro").MaxTorque.magnitude < 1 then
				CharacterMovers.EnableMover("StanceGyro", bigVector)
			end
			Humanoid.AutoRotate = false;
			Util.FaceForward(true)
		else
			Humanoid.AutoRotate = true; -- Allow the character to move with the rotation of the camera (Because our mouse isn't locked anymore)
		end
		
		-- Anti-Fling
		if (Vel.Y > 55) then
			RootPart.Velocity = Vector3.new(RootPart.Velocity, 55, RootPart.Velocity)
		end

		-- Setting walkspeed for snaring
		Humanoid.WalkSpeed = DesiredWalkSpeed * (1-math.clamp(Movement, 0, 0.5))

		-- Animations
		if (Debounces.CanAnimate) then
			-- Get the ground position of the user
			local Hit, Position = findGround(); --Should switch to 'RaycastParams'

			-- Determine what kind of animation we need to be doing based on the velocity of the character (Jumping, Walking, Running)
			if (Hit == nil) then -- Not on the ground
				AnimSpeed = 0.15;
				if (Vel.Y > 1) then -- Moving upwards
					Status = "Jumping";
				elseif (Vel.Y < -1) then -- Moving downwards
					Status = "Falling";
				end
			elseif (Hit ~= nil) then -- On the ground
				AnimSpeed = 0.2;
				if (CurrentSpeed > 22) then -- Moving faster than 22 stud/s (In any direction)
					Status = "Running";
				elseif (CurrentSpeed > 2) then -- Moving forward (In any direction)
					Status = "Walking";
				elseif (CurrentSpeed < 1) then -- Standing still
					Status = "Idle";
				end
			end

			-- Special Statuses
			if (Debounces.Stunned) then
				Status = "Stunned";
			end
			-- Kncoed down
			if (Debounces.Knocked) then
				Status = "Knocked";
			end
			-- Blocking
			if (Debounces.Blocking) then
				Status = "Blocking"
			end

			-- Referencing
			-- Set RootJoint weld
			-- Set Neck weld
			-- Set Right Arm weld
			-- Set Left Arm weld
			-- Set Right Leg weld
			-- Set Left Leg weld

			if (Status == "Jumping") then -- Jump Animation
				Anim = {
					Reference = {
						{0, 0, 0, 1, 0, 0, 0, 0.99619472, 0.087155737, 0, -0.087155737, 0.99619472},
						{0, 0, 0.300000012, 1, 0, 0, 0, 0.906307757, -0.42261827, 0, 0.42261827, 0.906307757},
						{-0.400000006, 0.424055874, 0.0897777602, 0.087155804, 0.99619472, 0, -0.862729847, 0.0754791349, 0.5, 0.49809736, -0.043577902, 0.866025388},
						{0.400000006, 0.430266947, 0.252477169, 0.173648223, -0.98480773, 0, 0.806707323, 0.142244309, 0.57357645, -0.56486249, -0.0996005312, 0.819152057},
						{-0.100000001, -0.400000006, 0.300000012, 0.981060326, 0.087155737, 0.172987193, -0.0703706518, 0.992403924, -0.100908287, -0.180467904, 0.086823903, 0.979741275},
						{0.100000001, -0.252094477, 0.204557627, 0.992403924, -0.087155737, -0.086823903, 0.0868240744, 0.996194661, -0.00759610534, 0.0871555507, 0, 0.99619472},
					},
					Priority = 1,
				}
			elseif (Status == "Falling") then -- Falling Animation
				Anim = {
					Reference = {
						{0, 0, 0, 1, 0, 0, 0, 0.984807789, -0.173647985, 0, 0.173647985, 0.984807789},
						{0, 0, 0.200000003, 1, 0, 0, 0, 0.939692557, -0.342020363, 0, 0.342020363, 0.939692557},
						{-0.400000006, 0.424055874, 0.0897777602, 0.087155804, 0.99619472, 0, -0.862729847, 0.0754791349, 0.5, 0.49809736, -0.043577902, 0.866025388},
						{0.400000006, 0.430266947, 0.252477169, 0.173648223, -0.98480773, 0, 0.806707323, 0.142244309, 0.57357645, -0.56486249, -0.0996005312, 0.819152057},
						{-0.117199093, -0.697336316, 0.503414571, 0.992403924, 0.0868240744, 0.0871555433, -0.087155737, 0.996194661, 0, -0.086823903, -0.0075961058, 0.996194661},
						{0.126014054, -0.398477852, 0.102657929, 0.992403924, -0.106423184, -0.0617142469, 0.087155737, 0.962250173, -0.257834166, 0.0868240818, 0.250496864, 0.964216173},
					},
					Priority = 1,
				}
			elseif (Status == "Idle") then -- Idle Animation
				Anim = {
					Reference = {
						{0, 0, 0, 0.965925872, 0, 0.258818835, 0, 1, 0, -0.258818835, 0, 0.965925872},
						{0, 0, 0, 0.965925872, 0, -0.258818835, -0.0225574989, 0.99619472, -0.0841858014, 0.257833958, 0.0871555507, 0.962250233},
						{-0.218201265, 0.980129659, 0.158434987, 0.95193404, 0.162475035, -0.259660214, 0.305247486, -0.432884663, 0.848195076, 0.0254075788, -0.886686325, -0.461672753},
						{0.115856647, 0.59394002, 0.562156737, 0.976552546, -0.21012646, -0.0468172282, -0.00187375396, -0.225760624, 0.974180996, -0.215270683, -0.951251268, -0.220860809},
						{-0.10957551, -0.00955975056, -0.235298753, 0.961749971, 0.0566948541, -0.267995179, -0.100468367, 0.983174682, -0.152557105, 0.254836828, 0.173646867, 0.951264262},
						{0.0323110223, -0.0191370845, 0.243833721, 0.863351047, -0.037505582, -0.503206849, 0.0747490451, 0.995737553, 0.0540314466, 0.499035448, -0.0842623636, 0.86247462},
					},
					Modifier = { -- Optional Table
						-- (cf1, cf2, cf3, 	ang1, ang2, ang3)
						-- (studs 	 		radians			)
						{0, -.1*sin(Iterator*3), 0, 0, 0, 0};
						-- RootJoint

						{0, 0, 0, MR(-2*sin(Iterator*3)), 0, 0};
						-- Neck

						{0, 0, 0, MR(-2*sin(Iterator*3)), 0, 0};
						-- RightArm

						{0, 0, 0, MR(-2*sin(Iterator*3)), 0, 0};
						-- LeftArm

						{0, 0.1*sin(Iterator*3), 0, 0, 0, 0};
						-- RightLeg

						{0, 0.1*sin(Iterator*3), 0, 0, MR(10), 0};
						-- LeftLeg
					}, 
					Priority = 1, -- Determines what level animations to override (>=)
				};
			elseif (Status == "Stunned") then -- Stun Animation
				Anim = {
					Reference = {
						{0, 0, 0, 1, 0, 0, 0, 0.939692616, -0.342020124, 0, 0.342020124, 0.939692616},
						{0, -0.236602515, 0.336602569, 1, 0, 0, 0, 0.766044676, -0.642787278, 0, 0.642787278, 0.766044676},
						{0, 0, 0.300000012, 1, 0, 0, 0, 0.939692616, 0.342020124, 0, -0.342020124, 0.939692616},
						{0, 0, 0.300000012, 1, 0, 0, 0, 0.939692557, 0.342020363, 0, -0.342020363, 0.939692557},
						{0.110466361, -0.134349108, 0.475913346, 0.96598351, -0.0740743726, 0.247767895, 0.00759612257, 0.965812445, 0.259130538, -0.258492231, -0.248433754, 0.933521509},
						{0.0653367564, -0.0129936188, 0.798853636, 0.99619472, 0.0298089553, -0.0818994343, 0.0075960909, 0.906421304, 0.422306418, 0.0868239105, -0.421321571, 0.902745664},
					},
					Priority = 1,
				}
			elseif (Status == "Knocked") then -- Knocked Animation
				Anim = {
					Reference = {
						{0, 0, 0, 1, 0, 0, 0, 0.819151878, 0.573576629, 0, -0.573576629, 0.819151878},
						{0, 0, 0.300000012, 1, 0, 0, 0, 0.906307697, -0.422618449, 0, 0.422618449, 0.906307697},
						{0.0517638139, 0.19318518, -0.400000006, 0.965925813, 0.183012635, -0.183012739, -0.258819044, 0.683012426, -0.683012843, 0, 0.707106948, 0.707106531},
						{-0.0347296372, 0.196961567, -0.300000012, 0.98480773, -0.122787803, 0.122787803, 0.173648179, 0.696364224, -0.696364224, 0, 0.707106769, 0.707106769},
						{-0.143023461, -0.491760463, 1.06862366, 0.99619472, 0.0818996057, 0.0298090316, -0.087155737, 0.936116815, 0.340718806, 0, -0.342020303, 0.939692616},
						{0.20691447, -1.16632164, 0.465907335, 0.99619472, -0.087155737, 4.6753982e-08, 0.0868240818, 0.992403865, -0.087156266, 0.00759612257, 0.0868246183, 0.996194661},
					},
					Priority = 2,
				}
			elseif (Status == "Blocking") then -- Blocking Animation
				Iterator = Iterator * 50
				Anim = {
					Reference = {
						{0, 0, 0, 0.984798372, 0.000592206488, -0.173698917, -0.0307366811, 0.98480773, -0.170906216, 0.170958817, 0.17364715, 0.96985513},
						{-0.000679016113, -4.76837158e-07, -0.199988604, 0.984793305, -0.0307365824, 0.170958087, 0.000592250319, 0.984806955, 0.173646584, -0.173698246, -0.17090492, 0.969847918},
						{-0.0987358093, 1.34503937, 0.425577164, 0.816741109, 0.145456821, -0.558368802, 0.556406915, -0.45478791, 0.695398092, -0.152788877, -0.878641009, -0.45237717},
						{0.43170929, 1.36873627, 0.670946121, 0.503955603, -0.00320468936, 0.86372292, -0.812190115, -0.342020184, 0.472618669, 0.293896198, -0.939687014, -0.174965829},
						{0.0584640503, 0.134105682, 0.792795181, 0.981081128, -0.0121526364, 0.193193987, -0.0532496423, 0.942579448, 0.329707056, -0.186108008, -0.33375594, 0.924098194},
						{0.312408447, -0.0301933289, -0.038548708, 0.985101759, -0.171967804, -0.00040609017, 0.148677588, 0.852868378, -0.500509679, 0.0864179507, 0.492993355, 0.865729868},
					},
					Priority = 1,
				};
			elseif (Status == "Walking") then -- Walking Animation
				Iterator = Iterator * 50
				Anim = {
					Reference = {
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
					},
					Modifier = { -- Optional Table
						-- (cf1, cf2, cf3, 	ang1, ang2, ang3)
						-- (studs 	 		radians			)
						{0, 0, 0, MR(4+2*cos(Iterator/12)), MR(0)+Vel.Y/60, MR(0+2*cos(Iterator/14)/2.3)+Vel.Y/60};
						-- RootJoint

						{0, 0, 0, MR(-10+2*cos(Iterator/12)), MR(0-2*cos(Iterator/14)/2.3), 0};
						-- Neck

						{0, 0.05*cos(Iterator/12), -sin(Iterator/14)/4, sin(Iterator/14)/2.8, -sin(Iterator/14)/3, MR(-10-7*cos(Iterator/12)/2)+Vel.Y/30};
						-- RightArm

						{0, -.05*cos(Iterator/12), sin(Iterator/14)/4, -sin(Iterator/14)/2.8, -sin(Iterator/14)/3, MR(10+7*cos(Iterator/12)/2)+Vel.Y/30};
						-- LeftArm

						{0, -cos(Iterator/14)*.3, sin(Iterator/14)*.1, sin(Iterator/14)*3*thetaL.Z, thetaL.X, 0}; --(sin(Iterator/14)*3*-thetaL.X)-Vel.Y/20};
						-- RightLeg

						{0, cos(Iterator/14)*.3, -sin(Iterator/14)*.1, sin(Iterator/14)*3*-thetaR.Z, thetaR.X, 0}; --(sin(Iterator/14)*3*thetaR.X)-Vel.Y/20};
						-- LeftLeg
						
						{0,0,0,0,0,0},
						-- Weapon 1
						
						{0,0,0,0,0,0},
						-- Weapon 2
					}, 
					Priority = 1,
				}
			elseif (Status == "Running") then -- Running Animation
				Iterator = Iterator * 25
				Anim = {
					Reference = {
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0.600000024, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{-0.600000024, -1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
						{0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1},
					},
					
					Modifier = { -- Optional Table
						-- (cf1, cf2, cf3, 	ang1, ang2, ang3)
						-- (studs 	 		radians			)
						{0, 0.2*cos(Iterator/3)/2, 0, -MR(-14+15*cos(Iterator/3)/2), MR(0-cos(Iterator/6)), MR(0)};
						-- RootJoint

						{0,0,-.2, MR(-8+12*cos(Iterator/3)/1.8), MR(0+3*cos(Iterator/6)), MR(0)};
						-- Neck

						{-.5+.1*cos(Iterator/6), 1, 0.1*cos(Iterator/6), MR(-20-20*cos(Iterator/6)/1.2), MR(0), MR(-10+10*cos(Iterator/6))};
						-- RightArm

						{.5+.1*cos(Iterator/6), 1, 0.1*cos(Iterator/6), MR(-20+20*cos(Iterator/6)/1.2), MR(0), MR(10+10*cos(Iterator/6))};
						-- LeftArm

						{0, -0.44*cos(Iterator/6)/2.4, -.15 + -sin(Iterator/6)/1.5, MR(10) + sin(Iterator/6)/1.7, MR(0+12*cos(Iterator/6)), 0};
						-- RightLeg

						{0, 0.44*cos(Iterator/6)/2.4, -.15 + sin(Iterator/6)/1.5, MR(10) + -sin(Iterator/6)/1.7, MR(0+12*cos(Iterator/6)), 0};
						-- LeftLeg
						
						{0, 0, 0, 0, 0, 0},
						-- Weapon 1
						
						{0, 0, 0, 0, 0, 0},
						-- Weapon 2
					}, 
					Priority = 1,
				}
			end

			local PlayTrack = true; -- Should we be overwriting default animations?

			if (Debounces.WeaponEqp==true) then -- Check if a weapon is equipped
				if CurrentEquip.Animations[Status] then -- Check if the weapon has custom animations

					local AnimationTable = CurrentEquip.Animations[Status]; -- Grab the keyframe sequence
					local KeyFrameMax = AnimationTable.t; -- Get the keyframe ending/length

					if (KeyFramePosition >= KeyFrameMax) or (Debounces.LastStatus~=Status) then
						KeyFramePosition = -1; -- Reset position on A) Status change or B) Keyframe length reach
					end

					KeyFramePosition = KeyFramePosition + 1 -- Iterate our current frame by 1

					for _, keyframe in pairs(AnimationTable) do -- Iterate all keyframes in the sequence
						if typeof(keyframe)=='table' then -- This is a frame
							local Animation = keyframe[1] -- Get the animation name
							local AnimationTimeAt = keyframe[2] -- Get the condition for playing the keyframe
							local Speed = keyframe[3] -- Get the speed at which we lerp to the keyframe

							if KeyFramePosition >= AnimationTimeAt and (PlayTrack==true) then -- If we haven't already played a keyframe on this frame,
								if Animation=='Damage' then -- Check if we should be dealing damage on this frame
									local Hit = Util.ScanMeleeRange(keyframe[6], keyframe[7]) -- Grab players in melee range
									for _, Victim in pairs(Hit) do -- Iterate the players
										Util.DoDamage(Victim, keyframe[2], "Kick") -- Send damage to the server based on tool's function
										if keyframe[3] then -- Check if a SoundId was specified
											Util.PlaySound(Head, keyframe[3], keyframe[4], keyframe[5]) -- Optionally play a sound
										end
									end
								else
									Util.PlayAnimationFrame(Animation, Speed) -- Play the frame at the designated position
								end
								PlayTrack = false; -- Signals that we have already played a keyframe on this cycle
								break
							end
						end
					end

				end
			end

			Debounces.LastStatus = Status;
			if PlayTrack then
				Replicator:FireEvent("Animation", "PlayAnimationByTable", "Main", Replicator:Encode{ -- Play animations directly
					Reference = Anim.Reference;
					Modifier = Anim.Modifier;
					Priority = Anim.Priority;
				}, AnimSpeed)
			end
		end

		-- Task scheduler.
		if (inQueue > 0) then
			for i, Task in next, Tasks do
				if Task then
					local TIME_LEFT = Task.TIME_REMAINING;
					if TIME_LEFT > 0 then
						Task.TIME_REMAINING = TIME_LEFT - dt
					else
						local ran, result = pcall(Task.TaskFunction); -- this better be a non-yielding function or im kicking your butt
						if not ran then -- give a stack that can be traced.
							error(('TASK EXCEPTION %s'):format(result))
						end
						Tasks[i] = nil;
						inQueue = inQueue - 1
					end
				end
			end
		end

		--Replicator:FireEvent("Effect", "Break", "Bright green", {Head.CFrame:components()}, 0.25, 0.25, 3)
		CurrentSpeed = Speed.magnitude
		vSpeed = Vel.Y;
	end
end

-------------------------------- CONNECTIONS -------------------------------------

Input.Connect();
Services.RunService.Heartbeat:connect(MainLoop);

Network:listen('UpdateData', function(Data)
	PlayerData = Data;
end)

Util.Schedule(function()
	Network:FireEvent("UpdateData")
end, 1, true) -- Set a recurring scheduled function to get server data

print("loaded")
--[[
Util.Schedule(function()
	Replicator:FireEvent("Animation", "LoadAnimationSetFromTable", require(Animations))
end, 5, true) -- Load the animation sets
--]]