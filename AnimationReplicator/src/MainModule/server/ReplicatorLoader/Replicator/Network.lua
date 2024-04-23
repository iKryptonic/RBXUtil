-- Remote Event handling

-- Service Provider
local Services	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;}); -- Setting up service provider

local Module = {};

local ReplicatedStorage = Services.ReplicatedStorage;
local Signals = {};

local Queue = {};
local Enabled = false;
local Remote;

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


local function HandleEvent(RemoteEventName, ...)
	if type(RemoteEventName) ~= "string" then return end;
	if Signals[RemoteEventName] then
		Signals[RemoteEventName]:Fire(...);
	end;
end;

-- Remote:Listen returns RBXScriptSignal

do
	local lastRemote = nil;

	local function CheckChild(Child)
		if not Child:IsA("RemoteEvent") or Child.Name ~= "WeaponReplicator" then return end;
		lastRemote = Child;
		if Remote then
			Remote = nil;
			Enabled = false;
		end

		if lastRemote ~= Child or Child.Parent ~= ReplicatedStorage then return end;
		Remote = Child;
		Enabled = true;

		Child.OnClientEvent:connect(HandleEvent);

		local queue = Queue;
		Queue = {};
		for i,v in pairs(queue) do
			Remote:FireServer(unpack(v, 1, v.len));
		end;
	end;

	for _, Object in ipairs(ReplicatedStorage:GetChildren()) do CheckChild(Object) end;
	ReplicatedStorage.ChildAdded:connect(CheckChild);
end;

function Module:FireEvent(RemoteName, ...)
	if not Enabled then 
		Queue[#Queue+1] = table.pack(self, RemoteName, ...) 
		return 
	end;

	Remote:FireServer(RemoteName, ...);
end

function Module:Listen(Command, ExecuteFunction)
	if type(Command) ~= "string" or type(ExecuteFunction) ~= "function" then return end;
	if not Signals[Command] then Signals[Command] = Signal.new() end;
	return Signals[Command]:connect(ExecuteFunction);
end;

return Module;