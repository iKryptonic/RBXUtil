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

]]
function Logger.Output(LogLevel: number, OutputText: string, ...: string)
	local FormattedOutputString: string = OutputText:format(...)

	if Logger.Settings.DebuggingEnabled then
		table.insert(Logger.OutputBuffer, {Type=LogLevel, Message=FormattedOutputString, Time=os.time()})
	else
		if LogLevel == 1 then
			print(FormattedOutputString)
		elseif LogLevel == 2 then
			warn(FormattedOutputString)
		elseif LogLevel == 3 then
			error(FormattedOutputString, 0)
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
end

--[[
    Print the output buffer
]]
function Logger.PrintOutputBuffer(this)
	this.Settings.DebuggingEnabled = false;

	for _, Log in pairs(this.OutputBuffer) do
		this.Output(Log.Type, Log.Message)
	end

	this.Settings.DebuggingEnabled = true;
end

--[[
	Flush and return n lines of the output buffer in a table format
]]
function Logger.FlushOutputBuffer(this, NumberOfLines: number)
	local OutputBuffer = table.clone(this.OutputBuffer);
	local Output = {};

	for i = 0, NumberOfLines do
		if OutputBuffer[#OutputBuffer - i] then
			table.insert(Output, OutputBuffer[i])
		end
	end

	return Output;
end

--[[
	Search logs for string
]]
function Logger.SearchLogs(this, SearchString: string)
	local OutputBuffer = table.clone(this.OutputBuffer);
	local Output = {};

	for _, Log in pairs(OutputBuffer) do
		if string.find(string.lower(Log.Message), string.lower(SearchString)) then
			table.insert(Output, Log)
		end
	end

	return Output;
end


return Logger;