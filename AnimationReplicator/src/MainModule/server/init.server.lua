-- @Name: server.lua
-- @Author: iKrypto
-- @Date: 10/25/20

wait();
script.Parent = nil;

-- Service Provider
local Services	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;}); -- Setting up service provider

-- Service Storage
local Players 			= Services.Players;
local ReplicatedStorage = Services.ReplicatedStorage
local CollectionS		= Services.CollectionService

-- Assets
local AssetData	= script:WaitForChild("AssetData", 10)
local Replicator= script:WaitForChild("Replicator", 10)
local Network	= require(script.Network);
local Player	= require(script.Player)

-- Indexing players for inventory handling
local PlayerData = {};

-- Create Folder for assets
local Assets; do 
	
	local AssetConnection = nil;
	local function CheckFolder()
		local Folder = ReplicatedStorage:FindFirstChild("Assets")
		if (not Folder) then
			Folder = Instance.new("Folder", ReplicatedStorage)
			Folder.Name = "Assets"
		end
		
		for _, Object in ipairs(AssetData:GetChildren()) do
			Object:Clone().Parent = Folder
		end
		
	return Folder
	end
	
	Assets = CheckFolder()
	
	AssetConnection = Assets.AncestryChanged:connect(function()
		Assets = CheckFolder();
		AssetConnection:disconnect();
	end)
	
end

-------------------------- functions --------------------------------

local function loadScript(Player)
	local LS = Replicator:Clone();
	wait();
	LS.Parent = Player.PlayerGui;
	LS.Disabled = false;
end

-- Essentially, this is playerAdded.
local function indexPlayer(P)
	repeat wait() warn("No Character Found") until (P and P.Character)
	loadScript(P);
	
	print("Loaded Localscript for ", P.Name)
	PlayerData[P] = Player.new(P);
	print("Created Player for ", P.Name)
end

local function removePlayer(Player)
	local Data = PlayerData[Player]
	if Data then
		Data.Save();
		Data.Kill();
	end
	PlayerData[Player] = nil;
end

Players.PlayerAdded:connect(function(p)
	indexPlayer(p);
end);

Players.PlayerRemoving:connect(function(p)
	removePlayer(p)
end)

for _, p in ipairs(Players:GetPlayers()) do indexPlayer(p) end;

-- Internal showtext stuff
local ShowText; do 
	ShowText =  function(Pos, Text, Time, Color)
		
		local function Create(Ins)
			return function(Table)
				local Object = Instance.new(Ins)
				for i,v in next,Table do
					Object[i]=v
				end
				return Object
			end
		end
		
		local Rate = (1 / 30)
		local Pos = (Pos or Vector3.new(0, 0, 0))
		local Text = (Text or "")
		local Time = (Time or 2)
		local Color = (Color or Color3.new(0, 0, .65))
		local EffectPart = Create("Part"){
			Reflectance = 0,
			Transparency = 1,
			CanCollide = false,
			Locked = true,
			BrickColor = BrickColor.new(Color),
			Name = "Effect",
			Size = Vector3.new(0, 0, 0),
			Material = "SmoothPlastic",
		}
		EffectPart.Anchored = true
		local BillboardGui = Create("BillboardGui"){
			Size = UDim2.new(5, 0, 5, 0),
			Adornee = EffectPart,
		};BillboardGui.Parent = EffectPart
		local TextLabel = Create("TextLabel"){
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = Text,
			TextColor3 = Color,
			TextScaled = true,
			Font = Enum.Font.ArialBold,
		};TextLabel.Parent=BillboardGui
		game.Debris:AddItem(EffectPart, (Time + 0.1))
		EffectPart.CFrame = CFrame.new(Pos) + Vector3.new(0, 0, 0)
		EffectPart.Parent = game:GetService("Workspace")
		delay(0, function()
			local Frames = (Time / Rate)
			for Frame = 1, Frames do
				wait(Rate)
				local Percent = (Frame / Frames)
				EffectPart.CFrame = CFrame.new(Pos) + Vector3.new(0, Percent, 0)
				TextLabel.TextTransparency = Percent
			end
			if EffectPart and EffectPart.Parent then
				EffectPart:Destroy()
			end
		end)
	end
end

----------------------------------- network listeners -----------------------------------

Network:listen('Replicate', function(Origin, ...)
	for _, Player in pairs(Players:GetPlayers()) do
		if (Player~=Origin) then
			Network:Fire(Player, 'Replicate', Origin, ...);
		end;
	end;
end);
Network:listen('Damage', function(Origin, Victim, Damage, AttackName)
	-- This is where a server damage check would come in
	Damage = math.floor(Damage);
	Damage = Damage + math.random(-7, 1)
	Damage = math.clamp(Damage, 3, 110)
	local Part = Victim.Head
	ShowText((Part.CFrame * CFrame.new(0, 0, (Part.Size.Z / 2)).Position + Vector3.new(math.random(-5,5), 1.5, 0)), tostring(Damage), 1.5, BrickColor.new('Bright red').Color)
	
	local VictimPlayer = Services.Players:GetPlayerFromCharacter(Victim);
	
	Victim.Humanoid:TakeDamage(Damage);
	
	if VictimPlayer then
		Network:Fire(VictimPlayer, 'OnHit')
	end;
end);
Network:listen('UpdateData', function(Origin)
	local Data = PlayerData[Origin].PlayerData
	if Data then
		Network:Fire(Origin, 'UpdateData', Data)
	end
end);
Network:listen('ChangeEquip', function(Origin, Status, ...)
	local Data = PlayerData[Origin]
	if Data then
		if Status=='Equip' then
			Data.EquipObject(...)
		elseif Status=='UnEquip' then
			Data.UnEquipObject(...)
		end
	else
		warn(("[ChangeEquip]: Could not run for %s."):format(Origin.Name))
	end
end);