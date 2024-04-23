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

function Remote:Fire(player, RemoteName, ...)
	local info = PlayerInfo[player]
	if not info then return end
	if (queueEnabled and (not info.Enabled)) then info.Queue[#info.Queue+1] = {len=select("#",...), ...} return end

	RemoteEvent:FireClient(player, RemoteName, ...)
end

function Remote:FireAllClients(RemoteName, ...)
	for _, Player in ipairs(Players:GetPlayers()) do
		self:Fire(Player, RemoteName, ...)
	end
end

function Remote:listen(cmd, fn)
	if type(cmd) ~= "string" or type(fn) ~= "function" then return end;
	if not Signals[cmd] then Signals[cmd] = Signal.new() end;
	return Signals[cmd]:connect(fn);
end;

local function receiveCallback(Player, RemoteName, ...)
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
	local function playerAdd(player)
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

	local function playerRem(player)
		pcall(function() PlayerInfo[player].playerConnect:disconnect() end)
		PlayerInfo[player] = nil
	end

	for i,v in pairs(Players:GetPlayers()) do playerAdd(v) end
	Players.PlayerAdded:connect(playerAdd)
	Players.PlayerRemoving:connect(playerRem)
end

do		
	local function makeEvent()
		for i,v in pairs(PlayerInfo) do
			v.Enabled = false
		end
		RemoteEvent = Instance.new("RemoteEvent")
		RemoteEvent.Name = "WeaponReplicator"
		RemoteEvent.OnServerEvent:Connect(receiveCallback)
		RemoteEvent.Changed:Connect(function(prop)
			if prop == "Name" and RemoteEvent.Name ~= "WeaponReplicator" then
				RemoteEvent:Destroy()
			end
		end)
		RemoteEvent.Parent = ReplicatedStorage
	end

	local function checkChild(child)
		if child == RemoteEvent or not child:IsA("RemoteEvent") then return end
		if child.Name == "WeaponReplicator" then child:Destroy() return end
		local chCon = nil

		chCon = child.Changed:Connect(function(prop)
			if prop == "Parent" then
				chCon:Disconnect()
			elseif prop == "Name" and child.Name == "WeaponReplicator" then
				chCon:Disconnect()
				child:Destroy()
			end
		end)
	end

	for i,v in pairs(ReplicatedStorage:GetChildren()) do checkChild(v) end
	ReplicatedStorage.ChildAdded:connect(checkChild)
	ReplicatedStorage.ChildRemoved:connect(function(child)
		if child ~= RemoteEvent then return end
		RemoteEvent:Destroy()
		RemoteEvent = nil
		spawn(makeEvent)
	end)
	spawn(makeEvent)
end

return Remote