local Players = game:GetService("Players");	
local MainScript = script:WaitForChild('server'):Clone();
local CS = script:WaitForChild("client"):Clone();
local CA = script:WaitForChild("CreateAnimator");

MainScript.Parent = game.ServerScriptService;
wait()
MainScript.Disabled = false;

local function LoadClient(Player)
	if not Player.Character then return end;
	
	local CreateAnimator = CA:Clone();
	local NewClientScript = CS:Clone();
	
	CreateAnimator.Parent = Player.Character
	NewClientScript.Parent = Player.Character
	
	NewClientScript.Disabled = false;
end;

local function HookPlayer(Player)
	Player.Chatted:Connect(function(Message)
		if Message == ";load" then
			LoadClient(Player)
		end
	end)
end;

for k,v in pairs(Players:GetPlayers()) do
	HookPlayer(v)
end

Players.PlayerAdded:Connect(function(Player)
	HookPlayer(Player)
end)

return 0