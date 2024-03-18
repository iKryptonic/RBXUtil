--!strict
--[[
	Logger.lua
	@Author: ikrypto
	@Date: 03-15-2024
]]

local Logger = {
	OutputBuffer = {},
	Settings = {
		DebuggingEnabled = true,
		MinimumLoggingLevel = 3
	},
	TaskScheduler = nil
};

function Logger:Initialize(TaskScheduler)
	self.TaskScheduler = TaskScheduler;
	self.Settings = TaskScheduler.Settings.LoggerSettings or self.Settings;

	return self;
end

--[[
    Outputs to the logger
    @param LogLevel: The level of the log
    @param OutputText: The text to output
    @param ...: The arguments to format the text with

    TODO:
    Append calling script to the output

]]
function Logger.Output(LogLevel: number, OutputText: string, ...: string)
	local FormattedOutputString: string = OutputText:format(...)

	if not Logger.Settings.DebuggingEnabled then
		table.insert(Logger.OutputBuffer, {Type=LogLevel, Message=FormattedOutputString, Time=os.time()})
	else
		if Logger.Settings.MinimumLoggingLevel <= LogLevel then
			if LogLevel == 1 then
				print(FormattedOutputString)
			elseif LogLevel == 2 then
				warn(FormattedOutputString)
			elseif LogLevel == 3 then
				error(FormattedOutputString, 0)
			end
		end
	end

	return FormattedOutputString
end

--[[
    Set the log level
    @param LogLevel: The level to set the log to
]]
function Logger:SetLogLevel(LogLevel: number)
	self.Settings.MinimumLoggingLevel = math.clamp(LogLevel, 1, 3)
end;

--[[
    Flush the output buffer
]]
function Logger.FlushOutputBuffer(this)
	this.Settings.DebuggingEnabled = false;

	for _, Log in pairs(this.OutputBuffer) do
		this.Output(Log.Type, Log.Message)
	end

	this.Settings.DebuggingEnabled = true;
end

return Logger;