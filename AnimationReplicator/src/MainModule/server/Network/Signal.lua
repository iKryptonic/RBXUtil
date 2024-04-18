local module = {}

function module.new()
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

return module
