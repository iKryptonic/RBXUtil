-- Remote Event Security funcz

-- Service Provider
local Services	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;}); -- Setting up service provider

local Module = {};

local ReplicatedStorage = Services.ReplicatedStorage;
local Signals = {};

local Queue = {};
local SendId = 0;
local RecvId = 0;
local Enabled = false;
local function updateValidator(n) return (n*1582831 + 19582923) % (2^32) end;
local function publicValidator(n) return (n-n%12424)/12424 end;

local Signal = {}; do

	function Signal.new()
		local this = {}
		local cons = {}
		local alive = true
		local bindable = Instance.new("BindableEvent")

		function this:connect(fn)
			assert(alive, "Signal has been destroyed")
			assert(self == this, "bad self")
			assert(type(fn) == "function", "Attempt to connect failed: Passed value is not a function")

			local con = bindable.Event:connect(function(...)
				local args = {...}
				fn(unpack(args, 1, #args))
			end)

			cons[#cons+1] = con
			return con
		end
		this.Connect = this.connect

		function this:wait(fn)
			assert(alive, "Signal has been destroyed")
			assert(self == this, "bad self")
			bindable.Event:wait()
			return 
		end
		this.Wait = this.wait

		function this:fire(...)
			assert(alive, "Signal has been destroyed")
			assert(self == this, "bad self")
			bindable:Fire(...)
		end
		this.Fire = this.fire

		function this:disconnect()
			assert(alive, "Signal has been destroyed")
			assert(self == this, "bad self")
			for i,v in pairs(cons) do
				v:Disconnect()
			end
			cons = {}
		end
		this.Disconnect = this.disconnect

		function this:destroy()
			assert(alive, "Signal has been destroyed")
			assert(self == this, "bad self")
			alive = false
			bindable:Destroy()
			bindable = nil
			cons = nil
			this = nil
		end
		this.Destroy = this.destroy

		return this
	end
end


local function HandleEvent(id, id2, RemoteEventName, ...)
	if type(id) ~= "number" or type(id2) ~= "number" or type(RemoteEventName) ~= "string" then return end;
	if id ~= publicValidator(RecvId) or id2 ~= publicValidator(updateValidator(RecvId)) then return end;
	RecvId = updateValidator(updateValidator(RecvId));
	if Signals[RemoteEventName] then
		Signals[RemoteEventName]:Fire(...);
	end;
end;

-- Remote:listen returns RBXScriptSignal

do
	local lastRemote = nil;
	local authCon = nil;

	local function checkChild(child)
		if not child:IsA("RemoteEvent") or child.Name ~= "WeaponReplicator" then return end;
		lastRemote = child;
		if Remote then
			Remote = nil;
			Enabled = false;
		end
		if authCon then
			authCon:Disconnect();
			authCon = nil;
		end

		delay(1, function()
			if lastRemote ~= child or child.Parent ~= ReplicatedStorage then return end;
			RecvId = math.random(1, 2^30);
			authCon = child.OnClientEvent:connect(function(msg, val, sid)
				if msg ~= "AuthResponse" or type(val) ~= "number" or type(sid) ~= "number" then return end;
				if val ~= publicValidator(RecvId) then return end;
				RecvId = updateValidator(RecvId);
				SendId = updateValidator(sid);
				Remote = child;
				Enabled = true;
				authCon:disconnect();
				authCon = nil;

				child.OnClientEvent:connect(HandleEvent);

				local queue = Queue;
				Queue = {};
				for i,v in pairs(queue) do
					Remote:FireServer(unpack(v, 1, v.len));
				end;
			end);
			local sentRecvId = RecvId;
			RecvId = updateValidator(RecvId);
			child:FireServer("AuthRequest", sentRecvId, publicValidator(sentRecvId));
		end);
	end;

	for i,v in pairs(ReplicatedStorage:GetChildren()) do checkChild(v) end;
	ReplicatedStorage.ChildAdded:connect(checkChild);
end;

function Module:FireEvent(RemoteName, ...)
	if not Enabled then Queue[#Queue+1] = table.pack(self, RemoteName, ...) return end;

	local id = publicValidator(SendId); SendId = updateValidator(SendId);
	local id2 = publicValidator(SendId); SendId = updateValidator(SendId);
	
	Remote:FireServer(id, id2, RemoteName, ...);
end

function Module:listen(cmd, fn)
	if type(cmd) ~= "string" or type(fn) ~= "function" then return end;
	if not Signals[cmd] then Signals[cmd] = Signal.new() end;
	return Signals[cmd]:connect(fn);
end;

return Module;