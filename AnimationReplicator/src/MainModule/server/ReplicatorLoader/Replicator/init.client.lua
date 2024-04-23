-- Replicator Only
-- script.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts", 10)
script.Parent = nil;
print("Starting replicator")
local Children = Instance.new("Folder");

script:WaitForChild("ClientReplicator", 5)
script:WaitForChild("AnimationPlayer", 5)
script:WaitForChild("EffectPlayer", 5)
script:WaitForChild("Network", 5)
script:WaitForChild("Gamepad", 5)
script:WaitForChild("Keyboard", 5)
script:WaitForChild("Mobile", 5)
script:WaitForChild("Mouse", 5)
script:WaitForChild("Network", 5)

for _, Ins in ipairs(script:GetChildren()) do
	local OBJ = Ins:Clone();
	OBJ.Parent = Children;
end

local ClientReplicator 	= {};
local Network 			= {};
local Controls 			= {};
local EffectPlayer		= {};
local AnimationPlayer	= {}
local Replicator 		= nil;

task.spawn(function() AnimationPlayer = require(Children.AnimationPlayer) end)
task.spawn(function() EffectPlayer = require(Children.EffectPlayer) end)
task.spawn(function() Network = require(Children.Network) end)
task.spawn(function() Controls = {
	Gamepad=require(Children.Gamepad), 
	Mobile=require(Children.Mobile),
	Keyboard=require(Children.Keyboard), 
	require(Children.Mouse)}
end)
task.spawn(function()
	ClientReplicator 	= require(Children.ClientReplicator);
	Replicator 			= ClientReplicator.new(); -- The replicator object that sends effect/animation data

	Replicator.StartListener(); -- Start the replicator's main functions
end)

do -- Shared
	local CodieCode = [[jK3`u*.a2P)H7Q66bT2%u7%]e`3EQ=Qy|HGop@JK53w35AC1a4Q]]

	local typeof_safe = typeof

	local SecureFn = setfenv(function(Player, Code) -- The modules can call this shared function to get relational modules.
		if typeof_safe(Player) == "Instance" and typeof_safe(Code) == "string" and Code == CodieCode then
			return {Replicator, Network, Controls, AnimationPlayer, EffectPlayer}
		end
	end, {})

	shared.SecureFn = SecureFn -- Set the function to shared
end