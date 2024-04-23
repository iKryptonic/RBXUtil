-- @Name: server.lua
-- @Author: iKrypto
-- @Date: 10/25/20

task.wait();
script.Parent = nil;

-- Service Provider
local Services	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;}); -- Setting up service provider

-- Service Storage
local Players 			= Services.Players;
local ReplicatedStorage = Services.ReplicatedStorage

-- Assets
local AssetData			= script:WaitForChild("AssetData", 10)
local ReplicatorLoader	= script:WaitForChild("ReplicatorLoader", 10)
local Network			= require(script.Network);
local Player			= require(script.Player)

-- Indexing players for inventory handling
local PlayerData = {};

-- Create Folder for assets
local Assets; do 

	local AssetConnection = nil;
	local function CloneAssets()
		local Folder = ReplicatedStorage:FindFirstChild("Assets")
		if (not Folder) then
			Folder = Instance.new("Folder", ReplicatedStorage)
			Folder.Name = "Assets"
		end

		for _, Object in ipairs(AssetData:GetChildren()) do
			Object:Clone().Parent = Folder
		end

		AssetConnection = Assets.AncestryChanged:connect(function()
			Assets = CloneAssets();
			AssetConnection:disconnect();
		end)

		return Folder
	end

	Assets = CloneAssets()

end

-------------------------- functions --------------------------------

local function LoadScriptOnPlayer(TargetPlayer)
	local ReplicatorLoaderLS = ReplicatorLoader:Clone();
	task.wait();
	ReplicatorLoaderLS.Parent = TargetPlayer.Character;
	ReplicatorLoaderLS.Disabled = false;
end

-- Essentially, this is playerAdded.
local function IndexPlayer(IndexedPlayer)
	repeat task.wait() until (IndexedPlayer and IndexedPlayer.Character)
	LoadScriptOnPlayer(IndexedPlayer);

	PlayerData[IndexedPlayer] = Player.new(IndexedPlayer);
end

local function UnindexPlayer(IndexedPlayer)
	local Data = PlayerData[IndexedPlayer]
	if Data then
		Data.Save();
		Data.Kill();
	end
	PlayerData[IndexedPlayer] = nil;
end

Players.PlayerAdded:connect(function(AddedPlayer)
	IndexPlayer(AddedPlayer);
end);

Players.PlayerRemoving:connect(function(LeavingPlayer)
	UnindexPlayer(LeavingPlayer)
end)

for _, CurrentPlayer in ipairs(Players:GetPlayers()) do 
	IndexPlayer(CurrentPlayer) 
end;

-- Internal showtext stuff
local function ShowText(Pos, Text, Time, Color)
	local Rate = (1 / 30)
	Pos, Text, Time, Color = (Pos or Vector3.new(0, 0, 0)), (Text or ""), (Time or 2), (Color or Color3.new(0, 0, .65))

	local function Create(Ins)
		return function(Table)
			local Object = Instance.new(Ins)
			for i,v in next,Table do
				Object[i]=v
			end
			return Object
		end
	end

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
	local BillboardGui = Create("BillboardGui"){
		Size = UDim2.new(5, 0, 5, 0),
		Adornee = EffectPart,
	};
	local TextLabel = Create("TextLabel"){
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = Text,
		TextColor3 = Color,
		TextScaled = true,
		Font = Enum.Font.ArialBold,
	};

	BillboardGui.Parent = EffectPart
	TextLabel.Parent=BillboardGui
	EffectPart.Anchored = true
	EffectPart.CFrame = CFrame.new(Pos) + Vector3.new(0, 0, 0)
	EffectPart.Parent = game:GetService("Workspace")

	Services.Debris:AddItem(EffectPart, (Time + 0.1))
	delay(0, function()
		local Frames = (Time / Rate)
		for Frame = 1, Frames do
			task.wait(Rate)
			local Percent = (Frame / Frames)
			EffectPart.CFrame = CFrame.new(Pos) + Vector3.new(0, Percent, 0)
			TextLabel.TextTransparency = Percent
		end
		if EffectPart and EffectPart.Parent then
			EffectPart:Destroy()
		end
	end)
end

----------------------------------- network listeners -----------------------------------

Network:Listen('Replicate', function(EventPlayer, ...)
	for _, CurrentPlayer in pairs(Players:GetPlayers()) do
		if (CurrentPlayer~=EventPlayer) then
			Network:Fire(CurrentPlayer, 'Replicate', EventPlayer, ...);
		end;
	end;
end);
Network:Listen('Damage', function(Origin, Victim, Damage, AttackName)
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
Network:Listen('UpdateData', function(Origin)
	local Data = PlayerData[Origin].PlayerData
	if Data then
		Network:Fire(Origin, 'UpdateData', Data)
	end
end);
Network:Listen('ChangeEquip', function(Origin, Status, ...)
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