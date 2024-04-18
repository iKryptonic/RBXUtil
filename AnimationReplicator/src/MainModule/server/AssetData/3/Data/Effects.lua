-- @Author: iKrypto
-- Services
local Services 	= setmetatable({}, {__index=function(self, index)return game:GetService(index); end;})

-- Determining Input Types
local IS_CONSOLE= Services.GuiService:IsTenFootInterface()
local IS_MOBILE = Services.UserInputService.TouchEnabled and not Services.UserInputService.MouseEnabled and not IS_CONSOLE

-- Common Services
local Players			= Services.Players;
local UIS				= Services.UserInputService;
local Lighting			= Services.Lighting;
local ReplicatedStorage	= Services.ReplicatedStorage;

-- Shortcuts
local V3 		= Vector3.new
local CF 		= CFrame.new
local CFA		= CFrame.Angles
local MR 		= math.rad
local MRand		= math.random
local Ins 		= Instance.new
local sin		= math.sin
local cos		= math.cos
local tr		= table.remove
local ti		= table.insert
local mh		= math.huge
local bigVector	= V3(mh, mh, mh)

return (function(EffectName)

	local Effects = {};

	local function AddEffect(EffectName, Fn)
		Effects[EffectName] = coroutine.wrap(Fn);
	end
	
	-- Returns 
	AddEffect("EmpowerCharacter", function(Player, Character, Network, Replicator)
		local BodyParts = {};
		
		for _, v in pairs(Character:GetChildren()) do
			if v:IsA("Part") then
				ti(BodyParts, v)
			end
		end

		local Bounding = {}
		for _, v in pairs(BodyParts) do
			local temp = {X=nil, Y=nil, Z=nil}
			temp.X = v.Size.X/2 * 10
			temp.Y = v.Size.Y/2 * 10
			temp.Z = v.Size.Z/2 * 10
			Bounding[v.Name] = temp
		end

		local function emitLightning()
			local Body1 = BodyParts[MRand(#BodyParts)]
			local Body2 = BodyParts[MRand(#BodyParts)]
			local Pos1 = V3(
				MRand(-Bounding[Body1.Name].X, Bounding[Body1.Name].X)/10,
				MRand(-Bounding[Body1.Name].Y, Bounding[Body1.Name].Y)/10,
				MRand(-Bounding[Body1.Name].Z, Bounding[Body1.Name].Z)/10
			)
			local Pos2 = V3(
				MRand(-Bounding[Body2.Name].X, Bounding[Body2.Name].X)/10,
				MRand(-Bounding[Body2.Name].Y, Bounding[Body2.Name].Y)/10,
				MRand(-Bounding[Body2.Name].Z, Bounding[Body2.Name].Z)/10
			)
			local SPos1 = Body1.Position + Pos1
			local SPos2 = Body2.Position + Pos2

			Replicator:FireEvent("Effect", "Lightning", SPos1, SPos2, 4, 2, 'New Yeller', 0.15, 0.4, 0.05)
		end

		for i = 1,25 do
			if (MRand() > .9) then
				emitLightning()
			end
		Services.RunService.RenderStepped:wait();
		end
	end)
	
	
	return Effects[EffectName]
end)