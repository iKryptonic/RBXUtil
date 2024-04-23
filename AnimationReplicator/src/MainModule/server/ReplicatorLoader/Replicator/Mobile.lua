-- @Name: Mobile
-- @Author: iKrypto

local Mobile = {
	Pitch = 0;
	Bank = 0;
	Yaw = 0;
	SwitchView = false;
	
	DeviceBank = 0;
	DevicePitch = 0;
	
}

local PI_HALF = math.pi * 0.5
local ATAN2 = math.atan2

local MAX_DEVICE_ROTATION = math.rad(60)

local userInput = game:GetService("UserInputService")
local initialGravity = Vector3.new()

local accelEnabled = userInput.AccelerometerEnabled

function ClampAndNormalize(n, lowHigh)
	return (n < -lowHigh and -lowHigh or n > lowHigh and lowHigh or n) / lowHigh
end


function DeviceGravityChanged(gravity)
	
	gravity = (gravity.Position + initialGravity)
	
	-- Thanks to Fractality_alt for the below algorithm:
	local gravX, gravY, gravZ = gravity.X, gravity.Y, gravity.Z
	local bank = (gravX > 0 and PI_HALF or -PI_HALF) - ATAN2(gravX, gravZ)
	local pitch = ATAN2(gravY, (gravX * gravX + gravZ * gravZ) ^ 0.5)
	
	Mobile.Bank = -ClampAndNormalize(bank, MAX_DEVICE_ROTATION)
	Mobile.Pitch = -ClampAndNormalize(pitch, MAX_DEVICE_ROTATION)
	
	Mobile.DeviceBank = bank
	Mobile.DevicePitch = pitch
	
end


if (accelEnabled) then
	initialGravity = userInput:GetDeviceGravity().Position
	userInput.DeviceGravityChanged:Connect(DeviceGravityChanged)
end

--[[
userInput.TouchLongPress:Connect(function(touchPositions, state, processed)
	if (processed or state ~= Enum.UserInputState.Begin) then return end
	Mobile.SwitchView = true
end)
]]


return Mobile