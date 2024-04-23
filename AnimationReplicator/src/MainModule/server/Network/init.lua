-- @Author: iKrypto

-- Setting up service provider
local Services = setmetatable({}, {__index=function(self, index)return game:GetService(index); end;})

local Remote = {};

local Players = Services.Players;
local ReplicatedStorage = Services.ReplicatedStorage;

local Signal = require(script.Signal)
local Signals = {};

-- Config
local queueEnabled = false; -- No RemoteEvent Queueing.

local RemoteEvent = nil;
local PlayerInfo = {};

function Remote:Fire(TargetPlayer, RemoteName, ...)
	local info = PlayerInfo[TargetPlayer]
	if not info then return end
	if (queueEnabled and (not info.Enabled)) then 
		info.Queue[#info.Queue+1] = {len=select("#",...), ...} 
	return 
	end

	RemoteEvent:FireClient(TargetPlayer, RemoteName, ...)
end

function Remote:FireAllClients(RemoteName, ...)
	for _, Player in ipairs(Players:GetPlayers()) do
		self:Fire(Player, RemoteName, ...)
	end
end

function Remote:Listen(Command, ExecuteFunction)
	if type(Command) ~= "string" or type(ExecuteFunction) ~= "function" then return end;
	if not Signals[Command] then 
		Signals[Command] = Signal.new() 
	end;

	return Signals[Command]:connect(ExecuteFunction);
end;

local function ReceiveCallback(Player, RemoteName, ...)
	local info = PlayerInfo[Player];
	if not info then return end;
	if not info.Enabled then
		info.Enabled = true;

		local queue = info.Queue;
		info.Queue = {};
		for i,v in pairs(queue) do
			Remote:Fire(Player, unpack(v, 1, v.len));
		end;
		return;
	end;

	if Signals[RemoteName] then
		Signals[RemoteName]:Fire(Player, ...);
	else
		warn("No listener set for ", RemoteName)
	end;
end;


do
	local function PlayerAdded(player)
		local info;

		info = {
			Player = player,
			Queue = {},
			Enabled = false,
			playerConnect = player.CharacterAdded:connect(function()
				--info.Enabled = false;
			end)
		}

		PlayerInfo[player] = info
	end

	local function PlayerRemoving(player)
		pcall(function() PlayerInfo[player].playerConnect:disconnect() end)
		PlayerInfo[player] = nil
	end

	for i,v in pairs(Players:GetPlayers()) do PlayerAdded(v) end
	Players.PlayerAdded:connect(PlayerAdded)
	Players.PlayerRemoving:connect(PlayerRemoving)
end

do		
	local function CreateRemoteEvent()
		for i,v in pairs(PlayerInfo) do
			v.Enabled = false
		end
		RemoteEvent = Instance.new("RemoteEvent")
		RemoteEvent.Name = "WeaponReplicator"
		RemoteEvent.OnServerEvent:Connect(ReceiveCallback)
		RemoteEvent.Changed:Connect(function(prop)
			if prop == "Name" and RemoteEvent.Name ~= "WeaponReplicator" then
				RemoteEvent:Destroy()
			end
		end)
		RemoteEvent.Parent = ReplicatedStorage
	end

	local function CheckChild(Child)
		if Child == RemoteEvent or not Child:IsA("RemoteEvent") then return end
		if Child.Name == "WeaponReplicator" then Child:Destroy() return end
		local ChangedConnection = nil

		ChangedConnection = Child.Changed:Connect(function(ChangedProperty)
			if ChangedProperty == "Parent" then
				ChangedConnection:Disconnect()
			elseif ChangedProperty == "Name" and Child.Name == "WeaponReplicator" then
				ChangedConnection:Disconnect()
				ChangedConnection:Destroy()
			end
		end)
	end

	for i,v in pairs(ReplicatedStorage:GetChildren()) do CheckChild(v) end
	ReplicatedStorage.ChildAdded:connect(CheckChild)
	ReplicatedStorage.ChildRemoved:connect(function(RemovedChild)
		if RemovedChild ~= RemoteEvent then return end
		RemoteEvent:Destroy()
		RemoteEvent = nil
		task.spawn(CreateRemoteEvent)
	end)
	task.spawn(CreateRemoteEvent)
end

return Remote