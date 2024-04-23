-- @Name: ClientReplicator
-- @Author: iKrypto

-- This handles the replication of animations across the client/server boundary

-- Service Provider

repeat wait() until (shared.SecureFn~=nil)

local Services	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;})-- Setting up service provider

local ScriptType= (Services.RunService:IsClient() and 'Client' or 'Server')-- Determining Script type
if (ScriptType~="Client") then error("ClientReplicator must be run on a client.", 0) end

-- Begin Script
local ClientReplicator 	= {};

local Owner 			= Services.Players.LocalPlayer

local Network			= shared.SecureFn(Owner, "jK3`u*.a2P)H7Q66bT2%u7%]e`3EQ=Qy|HGop@JK53w35AC1a4Q")[2];
local AnimationPlayer 	= shared.SecureFn(Owner, "jK3`u*.a2P)H7Q66bT2%u7%]e`3EQ=Qy|HGop@JK53w35AC1a4Q")[4];
local EffectPlayer 		= shared.SecureFn(Owner, "jK3`u*.a2P)H7Q66bT2%u7%]e`3EQ=Qy|HGop@JK53w35AC1a4Q")[5];

local Effects			= EffectPlayer.new();

function ClientReplicator.new()

	local obj 		= newproxy(true)-- Create object for the ClientReplicator metatable
	local Methods 	= {}; -- The tables methods which can be triggered by Table. or Table()
	local Properties= {}; -- The properties of the table which are only accessible via Table.
	local Signals = {};
	
	do
		local obj_meta	= getmetatable(obj) -- Cannot use setmetatable() on objects because they are userdata, we must getmetatable() on the newproxy() first

		obj_meta.__index=function(self, index)
			if Methods[index] then
				return Methods[index]; -- First look for a method
			elseif Properties[index] then
				return Properties[index]; -- Alternatively look for a property
			end;
			return nil; -- Else, exit and return nil
		end;
		obj_meta.__newindex=function(self)
			error("This table is readonly.", 0); -- Prevent addition of new keys to table
			return nil;
		end;
		obj_meta.__call=function(self, method, ...)
			if Methods[method] then
				return Methods[method](...) -- Allow for Table(Method, Argument) calls for method invocation
			end;
			return nil;
		end;
		obj_meta.__metatable="This metatable is locked."; -- Lock the newproxy's metatable
	end;

	-- Establish initial properties of the object
	Properties.Status = "stopped"; -- ClientReplicator's status
	Properties.ClassName = "ClientReplicator"; -- The ClassName of the object
	Properties.Name = "ClientReplicator"; -- The name of the object

	-- Setting up destroy with a few aliases
	local function Destroy()
		Properties.Status = "ended"; -- Set the ClientReplicator to ended to prevent any actions for executing (besides getState)
		Properties.Player = nil; -- Clear the player property of the now defunct ClientReplicator
		Properties.Connection:disconnect();
		Effects:Destroy(); -- Stop effects as well.

		for index, signal in next, Signals do
			signal:disconnect();
			Signals[index] = nil;
		end
		return;
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
	local function getState()
		local States = {
			["stopped"] = 0; -- stopped: 	Not initialized
			["running"] = 1; -- running: 	Currently animating a character
			["ended"]	= -1;-- ended:		Has been stopped permanently
		}
		return States[Properties.Status];
	end

	-------------------------------------------------------- BEGIN REPLICATOR CODE -----------------------------------

	local ReplicatedStorage = Services.ReplicatedStorage;
	local Players 			= Services.Players;
	local RunService 		= Services.RunService;

	local Remote			= Instance.new("RemoteEvent");

	-- API Elements to expose to remoteevent:
	-- LoadAnimationSetFromTable
	-- PlayAnimationByTable
	-- Destroy

	-- An ideal replicator would be able to:
	-- Re-Detect the RemoteEvent
	-- Send Commands to the RemoteEvent

	local Callbacks = {
		["Animation"] = {
			["LoadAnimationSetFromTable"] = true;
			["PlayAnimationByTable"] = true;
			["PlayAnimationCustom"] = true;
			["Destroy"] = true;
		};
		["Effect"] = true;
		["Sound"] = true;
	}

	local AnimationPlayers = {};

	local function GetAnimator(self, userId)
		return AnimationPlayers[userId];
	end

	-- Alias setting
	rawset(Methods, 'GetAnimator', GetAnimator)
	rawset(Methods, 'getAnimator', GetAnimator)
	-- End Alias setting

	local function HookPlayer(Player)
		if(getState()~=1) then error("This object is not running.", 0)  return end;
		-- Create animation player for every player that joins
		local Animation 	= AnimationPlayer.new(Player);
		task.wait()
		-- Begin the animation replication to be rendered by the client.
		Animation:Initialize() -- no more setup yielding
		AnimationPlayers[Player.userId] = Animation;
		return true;
	end

	local function ReplicateAnimation(Player, Callback, ...)
		local Operation = Callbacks['Animation'][Callback];
		if Operation then
			for userId, Animator in next, AnimationPlayers do
				if (Animator.Player==Player) then
					Animator(Callback, ...);
				end
			end
		end
	end

	local function Encode(self, Table)
		return Services.HttpService:JSONEncode(Table);
	end

	local function Decode(self, Table)
		return Services.HttpService:JSONDecode(Table);
	end
	-- Alias setting
	rawset(Methods, 'Decode', Decode)
	rawset(Methods, 'decode', Decode)
	rawset(Methods, 'Encode', Encode)
	rawset(Methods, 'encode', Encode)
	-- End Alias setting

	local function HandleEvent(Animatee, Type, ...)
		local args = table.pack(...);
		if (Type and (Callbacks[Type]~=nil)) then
			if Type=='Animation' then
				local Callback = args[1];
				local Name = args[2];
				local RefTable = args[3];
				local Spd = args[4];

				if Callbacks[Type][Callback] then
					ReplicateAnimation(Animatee, Callback, Name, RefTable, Spd)
				end
			elseif Type=='Effect' then
				Effects:QueueEffect(...)
			elseif Type=='Sound' then
				local Parent = args[1]
				local SoundId = args[2]

				if Parent and SoundId then

					local Volume = args[3] and args[3] or 1
					local Pitch = args[4] and args[4] or 1
					local OnRemove = args[5] and args[5] or false
					local RemoveEarly = args[6]

					local Sound = Instance.new("Sound")
					Sound.SoundId = "rbxassetid://"..SoundId
					Sound.Pitch = Pitch
					Sound.Volume = Volume
					Sound.PlayOnRemove = OnRemove
					task.wait()
					Sound.Parent = Parent;
					task.wait()
					Sound:Play();

					if OnRemove then
						Sound:Destroy'';
					elseif RemoveEarly then
						Services.Debris:AddItem(Sound, RemoveEarly)
					end

					coroutine.wrap(function()
						repeat task.wait() until (not Sound.IsPlaying)
						Services.Debris:AddItem(Sound);
					end)()

				end
			end
		end
	end

	local function FireEvent(self, Type, Callback, ...)
		Network:FireEvent('Replicate', Type, Callback, ...)
		HandleEvent(Owner, Type, Callback, ...)
	end

	-- Alias setting
	rawset(Methods, 'FireEvent', FireEvent)
	rawset(Methods, 'fireEvent', FireEvent)
	-- End Alias setting

	local function StartListener()

		rawset(Properties, 'Connection', Network:Listen("Replicate", HandleEvent)) -- Sets connection to RBXScriptSignal
		Effects:Initialize();

		rawset(Properties, 'Status', 'running')
		Services.Players.PlayerAdded:connect(function(Player) coroutine.wrap(HookPlayer)(Player) end) -- Hook new players

		for _, Player in next, Services.Players:GetPlayers() do 
			coroutine.wrap(HookPlayer)(Player)
		end -- Hook pre-existing players
	end



	-- Alias setting
	rawset(Methods, 'StartListener', StartListener)
	rawset(Methods, 'startListener', StartListener)
	-- End Alias setting
	return obj
end

return ClientReplicator