-- @Name: 	EffectPlayer.lua
-- @Author: iKrypto
-- @Date: 	10/10/2020

--[[
API:
	EffectPlayer.new(Player player) - Creates a new EffectPlayer Object
	
	- Properties [read-only]
		Status - EffectPlayer's status
		ClassName - The ClassName of the object
		Name - The name of the object
		EffectModel - The model effect parts are parenting to
		
	- Methods
		-- Fetches the current state of the replicator (-1 = dead, 0 = stopped, 1 = running)
		EffectPlayer::	getState
							GetState
						@Constructor
							EffectPlayer:GetState()
						@Returns Integer number
		
		-- Kills the replicator and prevents it executing any animations
		EffectPlayer::	destroy
							Destroy
							remove
							Remove
							stop
							Stop
						@Constructor
							EffectPlayer:Destroy()
						@Returns nil
		
		-- Loads a set of animations from a table format (found under examples)
		EffectPlayer::	QueueEffect
							queueEffect
						@Constructor
							EffectPlayer:QueueEffect(String EffectType, Tuple EffectParameters)
						@Returns nil
								
		-- Starts the EffectPlayer's main functions
		EffectPlayer::	Initialize
							initialize
						@Constructor
							EffectPlayer:Initialize()
						@Returns nil
]]

-- TODO: 

local EffectPlayer = {};
local Animations = {};

-- Setting up service provider
local Services = setmetatable({}, {__index=function(self, index)return game:GetService(index); end;})

-- Determining Script type
local ScriptType = (Services.RunService:IsClient() and 'Client' or 'Server')

-- This creates a "EffectPlayer" object

function EffectPlayer.new()
	local obj 		= newproxy(true)-- Create object for the EffectPlayer metatable
	local obj_meta 	= getmetatable(obj) -- Cannot use setmetatable() on objects because they are userdata, we must getmetatable() on the newproxy() first
	local Methods 	= {}; -- The tables methods which can be triggered by Table. or Table()
	local Properties= {}; -- The properties of the table which are only accessible via Table.

	local Meta = {
		__index=function(self, index)
			if Methods[index] then
				return Methods[index]; -- First look for a method
			elseif Properties[index] then
				return Properties[index]; -- Alternatively look for a property
			end;
			return nil; -- Else, exit and return nil
		end;
		__newindex=function(self)
			error("This object is readonly.", 0); -- Prevent addition of new keys to table
			return nil;
		end;
		__call=function(self, method, ...)
			if Methods[method] then
				return Methods[method](self, ...) -- Allow for Table(Method, Argument) calls for method invocation
			end;
			return nil;
		end;
		__tostring="EffectPlayer"; -- Override the tostring() behaviour of the table
		__metatable="This metatable is locked."; -- Lock the newproxy's metatable
	}

	-- Establish initial properties of the object
	Properties.Status = "stopped"; -- EffectPlayer's status
	Properties.ClassName = "EffectPlayer"; -- The ClassName of the object
	Properties.Name = "EffectPlayer"; -- The name of the object

	-- Setting up destroy with a few aliases
	local function Destroy()
		Properties.Status = "ended"; -- Set the EffectPlayer to ended to prevent any actions for executing (besides getState)
		Properties.Player = nil; -- Clear the player property of the now defunct EffectPlayer
		Properties.EffectModel:Destroy();
	end;

	-- Alias setting
	rawset(Methods, "destroy", Destroy)
	rawset(Methods, "Destroy", Destroy)
	rawset(Methods, "remove", Destroy)
	rawset(Methods, "Remove", Destroy)
	rawset(Methods, "stop", Destroy)
	rawset(Methods, "Stop", Destroy)
	-- End Alias Setting

	-- Setting up Getter Methods
	-- Returns the object's current state
	local function getState()
		local States = {
			["stopped"] = 0; -- stopped: 	Not initialized
			["running"] = 1; -- running: 	Currently animating a character
			["ended"]	= -1;-- ended:		Has been stopped permanently
		}
		return States[Properties.Status];
	end

	---------------------------------------- BEGINNING OF EFFECT METHODS -------------------------------------------------
	
	local Debris = Services.Debris
	local Effects = {};
	local cfn = CFrame.new
	local ud2 = UDim2.new
	local cfeaxyz = CFrame.Angles
	local mr = math.rad
	local mrand = math.random
	local v3 = Vector3.new
	local v2 = Vector2.new
	local ti = table.insert
	local tr = table.remove
	local bcn = BrickColor.new
	local cfeaxyz = CFrame.fromEulerAnglesXYZ;
	
	
	local Create = function(Ins)
		return function(Table)
			local Object = Instance.new(Ins);
			for i,v in next,Table do
				Object[i]=v;
			end;
			return Object;
		end;
	end;
	
	local function Encode(self, Table)
		return Services.HttpService:JSONEncode(Table);
	end

	local function Decode(self, Table)
		return Services.HttpService:JSONDecode(Table);
	end
	
	local function Subrange(T, First, Last)
		local sub = {}
		for i=First,Last do
			sub[#sub + 1] = T[i]
		end
		return sub
	end
	
	local EffectModel = (workspace:findFirstChild'Effects' and workspace:findFirstChild'Effects' or Create("Model")({Parent = workspace, Name = "Effects"}))
	
	rawset(Properties, 'EffectModel', EffectModel) -- Update the in-use effect model.
	
	local function QueueEffect(self, EffectType, ...)
		
		local function RemoveOutlines(part)
			part.TopSurface, part.BottomSurface, part.LeftSurface, part.RightSurface, part.FrontSurface, part.BackSurface = 10, 10, 10, 10, 10, 10
		end
		
		local CInstance;
			CInstance = {
				Part = {
					new = function(Parent, Material, Reflectance, Transparency, BColor, Name, Size)
						local Part = Create("Part")({
							Parent = Parent,
							Reflectance = Reflectance,
							Transparency = Transparency,
							CanCollide = false,
							Locked = true,
							BrickColor = bcn(tostring(BColor)),
							Name = Name,
							Size = Size,
							Material = Material
						})
						RemoveOutlines(Part)
						return Part
					end
				},
				Mesh = {
					new = function(Mesh, Part, MeshType, MeshId, OffSet, Scale)
						local Msh = Create(Mesh)({
							Parent = Part,
							Offset = OffSet,
							Scale = Scale
						})
						if Mesh == "SpecialMesh" then
							Msh.MeshType = MeshType
							Msh.MeshId = MeshId
						end
						return Msh
					end
				},
				Weld = {
					new = function(Parent, Part0, Part1, C0, C1)
						local Weld = Create("Weld")({
							Parent = Parent,
							Part0 = Part0,
							Part1 = Part1,
							C0 = C0,
							C1 = C1
						})
						return Weld
					end
				},
				Sound = {
					new = function(id, par, vol, pit)
						coroutine.wrap(function()
							local Sound = Create("Sound")({
								Volume = vol,
								Pitch = pit or 1,
								SoundId = "rbxassetid://" .. id,
								Parent = par or workspace
							})
							Sound:play()
							Debris:AddItem(Sound, 10)
						end)()
					end
				},
				Decal = {
					new = function(Color, Texture, Transparency, Name, Parent)
						local Decal = Create("Decal")({
							Color3 = Color,
							Texture = "rbxassetid://" .. Texture,
							Transparency = Transparency,
							Name = Name,
							Parent = Parent
						})
						return Decal
					end
				},
				BillboardGui = {
					new = function(Parent, Image, Position, Size)
						local BillPar = CInstance.Part.new(Parent, "SmoothPlastic", 0, 1, bcn("Black"), "BillboardGuiPart", v3(1, 1, 1))
						BillPar.CFrame = cfn(Position)
						local Bill = Create("BillboardGui")({
							Parent = BillPar,
							Adornee = BillPar,
							Size = ud2(1, 0, 1, 0),
							SizeOffset = v2(Size, Size)
						})
						local d = Create("ImageLabel", Bill)({
							Parent = Bill,
							BackgroundTransparency = 1,
							Size = ud2(1, 0, 1, 0),
							Image = "rbxassetid://" .. Image
						})
						return BillPar
					end
				},
				ParticleEmitter = {
					new = function(Parent, Color1, Color2, LightEmission, Size, Texture, Transparency, ZOffset, Accel, Drag, LockedToPart, VelocityInheritance, EmissionDirection, Enabled, LifeTime, Rate, Rotation, RotSpeed, Speed, VelocitySpread)
						local Particle = Create("ParticleEmitter")({
							Parent = Parent,
							Color = ColorSequence.new(Color1, Color2),
							LightEmission = LightEmission,
							Size = Size,
							Texture = Texture,
							Transparency = Transparency,
							ZOffset = ZOffset,
							Acceleration = Accel,
							Drag = Drag,
							LockedToPart = LockedToPart,
							VelocityInheritance = VelocityInheritance,
							EmissionDirection = EmissionDirection,
							Enabled = Enabled,
							Lifetime = LifeTime,
							Rate = Rate,
							Rotation = Rotation,
							RotSpeed = RotSpeed,
							Speed = Speed,
							VelocitySpread = VelocitySpread
						})
						return Particle
					end
				},
				CreateTemplate = {}
			}
		
		-- The called functions from parameters of the function.
		local Effectz = {
			Block = {
				new = function(brickcolor, cframe, x1, y1, z1, x3, y3, z3, incdelay, Type)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, brickcolor, "Effect", v3())
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe))
					local msh = CInstance.Mesh.new("BlockMesh", prt, "", "", v3(0, 0, 0), v3(x1, y1, z1))
					Debris:AddItem(prt, 10)
					if Type == 1 or Type == nil then
						ti(Effects, {
							prt,
							"Block1",
							incdelay,
							x3,
							y3,
							z3,
							msh
						})
					elseif Type == 2 then
						ti(Effects, {
							prt,
							"Block2",
							incdelay,
							x3,
							y3,
							z3,
							msh
						})
					end
				end
			},
			Crown = {
				new = function(brickcolor, cframe, x1, y1, z1, x3, y3, z3, incdelay)
					
				end
			},
			Cylinder = {
				new = function(brickcolor, cframe, x1, y1, z1, x3, y3, z3, incdelay)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, brickcolor, "Effect", v3(0.2, 0.2, 0.2))
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe))
					local msh = CInstance.Mesh.new("CylinderMesh", prt, "", "", v3(0, 0, 0), v3(x1, y1, z1))
					Debris:AddItem(prt, 2)
					Effects[#Effects + 1] = {
						prt,
						"Cylinder",
						incdelay,
						x3,
						y3,
						z3,
						msh
					}
				end
			},
			Head = {
				new = function(brickcolor, cframe, x1, y1, z1, x3, y3, z3, incdelay)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, brickcolor, "Effect", v3())
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe))
					local msh = CInstance.Mesh.new("SpecialMesh", prt, "Head", "nil", v3(0, 0, 0), v3(x1, y1, z1))
					Debris:AddItem(prt, 10)
					ti(Effects, {
						prt,
						"Cylinder",
						incdelay,
						x3,
						y3,
						z3,
						msh
					})
				end
			},
			Sphere = {
				new = function(brickcolor, cframe, x1, y1, z1, x3, y3, z3, incdelay)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, brickcolor, "Effect", v3())
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe))
					local msh = CInstance.Mesh.new("SpecialMesh", prt, "Sphere", "", v3(0, 0, 0), v3(x1, y1, z1))
					Debris:AddItem(prt, 10)
					ti(Effects, {
						prt,
						"Cylinder",
						incdelay,
						x3,
						y3,
						z3,
						msh
					})
				end
			},
			Electricity = {
				new = function(cff, x, y, z)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, bcn("Lime green"), "Part", v3(1, 1, 1))
					prt.Anchored = true
					prt.CFrame = cff * cfn(mrand(-x, x), mrand(-y, y), mrand(-z, z))
					prt.CFrame = cfn(prt.Position)
					Debris:AddItem(prt, 2)
					local xval = mrand() / 2
					local yval = mrand() / 2
					local zval = mrand() / 2
					local msh = CInstance.Mesh.new("BlockMesh", prt, "", "", v3(0, 0, 0), v3(xval, yval, zval))
					ti(Effects, {
						prt,
						"Elec",
						0.1,
						x,
						y,
						z,
						xval,
						yval,
						zval
					})
				end
			},
			Ring = {
				new = function(brickcolor, cframe, x1, y1, z1, x3, y3, z3, incdelay)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, brickcolor, "Effect", v3())
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe))
					local msh = CInstance.Mesh.new("CylinderMesh", prt, "", "", v3(0, 0, 0), v3(x1, y1, z1))
					Debris:AddItem(prt, 10)
					ti(Effects, {
						prt,
						"Cylinder",
						incdelay,
						x3,
						y3,
						z3,
						msh
					})
				end
			},
			Wave = {
				new = function(brickcolor, cframe, x1, y1, z1, x3, y3, z3, incdelay)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, bcn(brickcolor), "Effect", v3())
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe))
					local msh = CInstance.Mesh.new("SpecialMesh", prt, "FileMesh", "rbxassetid://20329976", v3(0, 0, 0), v3(x1, y1, z1))
					Debris:AddItem(prt, 10)
					ti(Effects, {
						prt,
						"Cylinder",
						incdelay,
						x3,
						y3,
						z3,
						msh
					})
				end
			},
			Break = {
				new = function(brickcolor, cframe, x1, y1, z1)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, brickcolor, "Effect", v3(0.5, 0.5, 0.5))
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe)) * cfeaxyz(mrand(-50, 50), mrand(-50, 50), mrand(-50, 50))
					local msh = CInstance.Mesh.new("SpecialMesh", prt, "Sphere", "", v3(0, 0, 0), v3(x1, y1, z1))
					local num = mrand(10, 50) / 1000
					Debris:AddItem(prt, 10)
					ti(Effects, {
						prt,
						"Shatter",
						num,
						prt.CFrame,
						mrand() - mrand(),
						0,
						mrand(50, 100) / 100
					})
				end
			},
			Fire = {
				new = function(brickcolor, cframe, x1, y1, z1, incdelay)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 0, brickcolor, "Effect", v3())
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe))
					msh = CInstance.Mesh.new("BlockMesh", prt, "", "", v3(0, 0, 0), v3(x1, y1, z1))
					Debris:AddItem(prt, 10)
					ti(Effects, {
						prt,
						"Fire",
						incdelay,
						1,
						1,
						1,
						msh
					})
				end
			},
			FireWave = {
				new = function(brickcolor, cframe, x1, y1, z1)
					local prt = CInstance.Part.new(EffectModel, "Neon", 0, 1, brickcolor, "Effect", v3())
					prt.Anchored = true
					prt.CFrame = cfn(unpack(cframe))
					msh = CInstance.Mesh.new("BlockMesh", prt, "", "", v3(0, 0, 0), v3(x1, y1, z1))
					local d = Create("Decal")({
						Parent = prt,
						Texture = "rbxassetid://26356434",
						Face = "Top"
					})
					local d = Create("Decal")({
						Parent = prt,
						Texture = "rbxassetid://26356434",
						Face = "Bottom"
					})
					Debris:AddItem(prt, 10)
					ti(Effects, {
						prt,
						"FireWave",
						1,
						30,
						mrand(400, 600) / 100,
						msh
					})
				end
			},
			Lightning = {
				new = function(p0, p1, tym, ofs, col, th, tra, last)
					local magz = (p0 - p1).magnitude
					local curpos = p0
					local trz = {
						-ofs,
						ofs
					}
					for i = 1, tym do
						local li = CInstance.Part.new(EffectModel, "Neon", 0, tra or 0.4, col, "Ref", v3(th, th, magz / tym))
						li.Anchored = true;
						local ofz = v3(trz[mrand(1, 2)], trz[mrand(1, 2)], trz[mrand(1, 2)])
						local trolpos = cfn(curpos, p1) * cfn(0, 0, magz / tym).p + ofz
						li.Material = "Neon"
						if tym == i then
							local magz2 = (curpos - p1).magnitude
							li.Size = v3(th, th, magz2)
							li.CFrame = cfn(curpos, p1) * cfn(0, 0, -magz2 / 2)
							ti(Effects, {
								li,
								"Disappear",
								last
							})
						else
							li.CFrame = cfn(curpos, trolpos) * cfn(0, 0, magz / tym / 2)
							curpos = li.CFrame * cfn(0, 0, magz / tym / 2).p
							Debris:AddItem(li, 10)
							ti(Effects, {
								li,
								"Disappear",
								last
							})
						end
					end
				end
			},
			EffectTemplate = {}
		}
		if (Effectz[EffectType]) then
			Effectz[EffectType].new(...)
		else
			warn(("Effect %s is not handled."):format(EffectType))
		end
	end

	-- Alias setting
	rawset(Methods, "queueEffect", QueueEffect)
	rawset(Methods, "QueueEffect", QueueEffect)
	-- End Alias setting

	local function Initialize(self)
		if getState()~=0 then error("This object has already been initialized!", 0) return end

		rawset(Properties, 'Status', 'running')
		EffectModel:ClearAllChildren() -- Delete any old effects.
		
		coroutine.wrap(function()
			local waitEvent = ((ScriptType=='Client') and Services.RunService.RenderStepped or Services.RunService.Heartbeat)
			
			while waitEvent:wait() do
				if (getState()==-1) then break end;
				if 0 < #Effects then
					for e = 1, #Effects do
						if Effects[e] ~= nil then
							local Thing = Effects[e]
							if Thing ~= nil then
								local Part = Thing[1]
								local Mode = Thing[2]
								local Delay = Thing[3]
								local IncX = Thing[4]
								local IncY = Thing[5]
								local IncZ = Thing[6]
								if Thing[2] == "Shoot" then
									local Look = Thing[1]
									local move = 30
									if Thing[8] == 3 then
										move = 10
									end
									local hit, pos = rayCast(Thing[4], Thing[1], move, m)
									if Thing[10] ~= nil then
										da = pos
										cf2 = CFrame.new(Thing[4], Thing[10].Position)
										cfa = CFrame.new(Thing[4], pos)
										tehCF = cfa:lerp(cf2, 0.2)
										Thing[1] = tehCF.lookVector
									end
									local mag = (Thing[4] - pos).magnitude
									Effects["Head"].Create(Torso.BrickColor, CFrame.new((Thing[4] + pos) / 2, pos) * CFrame.Angles(1.57, 0, 0), 1, mag * 5, 1, 0.5, 0, 0.5, 0.2)
									if Thing[8] == 2 then
										Effects["Ring"].Create(Torso.BrickColor, CFrame.new((Thing[4] + pos) / 2, pos) * CFrame.Angles(1.57, 0, 0) * CFrame.fromEulerAnglesXYZ(1.57, 0, 0), 1, 1, 0.1, 0.5, 0.5, 0.1, 0.1, 1)
									end
									Thing[4] = Thing[4] + Look * move
									Thing[3] = Thing[3] - 1
									if 2 < Thing[5] then
										Thing[5] = Thing[5] - 0.3
										Thing[6] = Thing[6] - 0.3
									end
									if hit ~= nil then
										Thing[3] = 0
										if Thing[8] == 1 or Thing[8] == 3 then
											Damage(hit, hit, Thing[5], Thing[6], Thing[7], "Normal", RootPart, 0, "", 1)
										else
											if Thing[8] == 2 then
												Damage(hit, hit, Thing[5], Thing[6], Thing[7], "Normal", RootPart, 0, "", 1)
												if (hit.Parent:findFirstChild("Humanoid")) ~= nil or (hit.Parent.Parent:findFirstChild("Humanoid")) ~= nil then
													ref = CFuncs.Part.Create(workspace, "Neon", 0, 1, BrickColor.new(MColor), "Reference", Vector3.new())
													ref.Anchored = true
													ref.CFrame = CFrame.new(pos)
													CFuncs["Sound"].Create("161006093", ref, 1, 1.2)
													game:GetService("Debris"):AddItem(ref, 0.2)
													Effects["Block"].Create(Torso.BrickColor, CFrame.new(ref.Position) * CFrame.fromEulerAnglesXYZ(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50)), 1, 1, 1, 10, 10, 10, 0.1, 2)
													Effects["Ring"].Create(BrickColor.new("Bright yellow"), CFrame.new(ref.Position) * CFrame.fromEulerAnglesXYZ(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50)), 1, 1, 0.1, 4, 4, 0.1, 0.1)
													MagnitudeDamage(ref, 15, Thing[5] / 1.5, Thing[6] / 1.5, 0, "Normal", "", 1)
												end
											end
										end
										ref = CFuncs.Part.Create(workspace, "Neon", 0, 1, BrickColor.new(MColor), "Reference", Vector3.new())
										ref.Anchored = true
										ref.CFrame = CFrame.new(pos)
										Effects["Sphere"].Create(Torso.BrickColor, CFrame.new(pos), 5, 5, 5, 1, 1, 1, 0.07)
										game:GetService("Debris"):AddItem(ref, 1)
									end
									if Thing[3] <= 0 then
										table.remove(Effects, e)
									end
								end
								do
									do
										if Thing[2] == "FireWave" then
											if Thing[3] <= Thing[4] then
												Thing[1].CFrame = Thing[1].CFrame * CFrame.fromEulerAnglesXYZ(0, 1, 0)
												Thing[3] = Thing[3] + 1
												Thing[6].Scale = Thing[6].Scale + Vector3.new(Thing[5], 0, Thing[5])
											else
												Part.Parent = nil
												table.remove(Effects, e)
											end
										end
										if Thing[2] ~= "Shoot" and Thing[2] ~= "Wave" and Thing[2] ~= "FireWave" then
											if Thing[1].Transparency <= 1 then
												if Thing[2] == "Block1" then
													Thing[1].CFrame = Thing[1].CFrame * CFrame.fromEulerAnglesXYZ(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
													Mesh = Thing[7]
													Mesh.Scale = Mesh.Scale + Vector3.new(Thing[4], Thing[5], Thing[6])
													Thing[1].Transparency = Thing[1].Transparency + Thing[3]
												else
													if Thing[2] == "Block2" then
														Thing[1].CFrame = Thing[1].CFrame
														Mesh = Thing[7]
														Mesh.Scale = Mesh.Scale + Vector3.new(Thing[4], Thing[5], Thing[6])
														Thing[1].Transparency = Thing[1].Transparency + Thing[3]
													else
														if Thing[2] == "Fire" then
															Thing[1].CFrame = CFrame.new(Thing[1].Position) + Vector3.new(0, 0.2, 0)
															Thing[1].CFrame = Thing[1].CFrame * CFrame.fromEulerAnglesXYZ(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
															Thing[1].Transparency = Thing[1].Transparency + Thing[3]
														else
															if Thing[2] == "Cylinder" then
																Mesh = Thing[7]
																Mesh.Scale = Mesh.Scale + Vector3.new(Thing[4], Thing[5], Thing[6])
																Thing[1].Transparency = Thing[1].Transparency + Thing[3]
															else
																if Thing[2] == "Blood" then
																	Mesh = Thing[7]
																	Thing[1].CFrame = Thing[1].CFrame * CFrame.new(0, 0.5, 0)
																	Mesh.Scale = Mesh.Scale + Vector3.new(Thing[4], Thing[5], Thing[6])
																	Thing[1].Transparency = Thing[1].Transparency + Thing[3]
																else
																	if Thing[2] == "Elec" then
																		Thing[1].Size = Thing[1].Size + Vector3.new(Thing[7], Thing[8], Thing[9])
																		Thing[1].Transparency = Thing[1].Transparency + Thing[3]
																	else
																		if Thing[2] == "Disappear" then
																			Thing[1].Transparency = Thing[1].Transparency + Thing[3]
																		elseif Thing[2] == "Shatter" then
																			Thing[1].Transparency = Thing[1].Transparency + Thing[3]
																			Thing[4] = Thing[4] * CFrame.new(0, Thing[7], 0)
																			Thing[1].CFrame = Thing[4] * CFrame.fromEulerAnglesXYZ(Thing[6], 0, 0)
																			Thing[6] = Thing[6] + Thing[5]
																		end
																	end
																end
															end
														end
													end
												end
											else
												Part.Parent = nil
												table.remove(Effects, e)
											end
										end
									end
								end
							end
						end
					end
				end
			end;
		end)()
	end

	-- Alias setting
	rawset(Methods, "Initialize", Initialize)
	rawset(Methods, "initialize", Initialize)
	-- End Alias setting

	return setmetatable(obj_meta, Meta)
end


return EffectPlayer;