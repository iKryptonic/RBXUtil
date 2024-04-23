-- Thanks to fbd_1 for the debugging on this replication stuff
local Replicator = script:WaitForChild("Replicator", 5)
local Owner = game:GetService("Players").LocalPlayer;

if Replicator then
	Replicator = Replicator:Clone();
	Replicator.Parent = Owner.PlayerGui;
	task.wait();
	Replicator.Enabled = true;
end