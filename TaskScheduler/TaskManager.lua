--[[
    TaskManager.lua
	@Author: ikrypto
	@Date: 03-19-2024

	TODO: -Revamp performance tab to utilize the
			TaskScheduler's performance manager fully 
			through dynamic views
		  -Implement more commands for console
]]

-- Owner
local Owner = game.Players.LocalPlayer;

-- ScreenGui
local MainGui = script.Parent.Parent:WaitForChild("Main")

-- TaskManager
local TaskManager = {
	GUI = {
		["MainFrame"] = MainGui,
		["TopBarContainer"] = MainGui:WaitForChild("TopBar"),
		["BottomBarContainer"] = MainGui:WaitForChild("BottomBar"),
		["BodyContainer"] = MainGui:WaitForChild("Body"),
		["TabContainer"] = MainGui:WaitForChild("TopBar").TabContainer,
		["Title"] = MainGui:WaitForChild("TopBar").Title,
		["References"] = MainGui:WaitForChild("References"),
	};

	ActivePage = nil,
	TaskScheduler = nil,
};

-- Services
local RunService = game:GetService("RunService")

-- Metadata
local BottomBarMetadata = {
	["ServerTick"] = {
		UpdateFunction = function(this)
			local ServerTick = math.round(1/RunService.Heartbeat:Wait());

			this.ObjectReference.Text = "[Server Tick] " .. tostring(ServerTick);
		end,
		ObjectReference = TaskManager.GUI.BottomBarContainer.ServerTick,
	},
	["ServerTime"] = {
		UpdateFunction = function(this)
			local ServerTime = os.date("%I:%M:%S %p");

			this.ObjectReference.Text = "[Server Time] " .. ServerTime;
		end,
		ObjectReference = TaskManager.GUI.BottomBarContainer.ServerTime
	},
	["TaskCount"] = {
		UpdateFunction = function(this)
			if not TaskManager.TaskScheduler then return end;
			
			local TaskCount = TaskManager.TaskScheduler:GetTaskCount();

			this.ObjectReference.Text = "[Task Count] " .. tostring(TaskCount);
		end,
		ObjectReference = TaskManager.GUI.BottomBarContainer.TaskCount
	},
	["TaskQueue"] = {
		UpdateFunction = function(this)
			if not TaskManager.TaskScheduler then return end;
			local TaskQueue = TaskManager.TaskScheduler.PerformanceManager:GetActiveTasks();
			local Count = 0;

			for _, _ in next, TaskQueue do
				Count += 1;
			end;

			this.ObjectReference.Text = "[Running Tasks] " .. tostring(Count);
		end,
		ObjectReference = TaskManager.GUI.BottomBarContainer.TaskQueue
	},
	["UserInfo"] = {
		UpdateFunction = function(this)
			local UserInfo = Owner.Name .. " (" .. Owner.UserId .. ")";

			this.ObjectReference.Text = "[UserId] " .. tostring(UserInfo);
		end,
		ObjectReference = TaskManager.GUI.BottomBarContainer.UserInfo
	}
}

local ObjectReferences = {
	TaskCardReference = TaskManager.GUI.References.TaskCardReference:Clone(),
	TaskDataReference = TaskManager.GUI.References.TaskDataReference:Clone(),
	SettingReference = TaskManager.GUI.References.SettingReference:Clone(),
}

-- Pages
local Pages = {
	["TaskList"] = {
		Container = TaskManager.GUI.BodyContainer.TaskListView.Container,
		Tab = TaskManager.GUI.TabContainer.TaskList,
		Constants = {
			SelectedTask = nil,
		},
		Connections = {},

		UpdateFunction = function(this)
			local function ClearTaskMetadata()
				for _, TaskData in next, this.Container.TaskMetadata:GetChildren() do
					if not TaskData:IsA("TextLabel") then continue end;

					TaskData:Destroy();
				end;
			end;

			local function UpdateTaskList()
				if not TaskManager.TaskScheduler then return end;
				-- Get the tasks
				local Tasks = TaskManager.TaskScheduler.Tasks;

				-- Helper method for creating task cards
				local function CreateTaskCard(TaskName: string)
					local TaskCard = ObjectReferences.TaskCardReference:Clone();
					local TaskLabelObject = TaskCard:FindFirstChildWhichIsA("TextLabel");

					-- Hook into click event
					local TaskCardConnection = TaskCard.MouseButton1Click:Connect(function()
						this.Constants.SelectedTask = nil;
						ClearTaskMetadata();
						this.Constants.SelectedTask = TaskName;
					end);

					TaskLabelObject.Text = TaskName;
					TaskCard.Name = TaskName;
					TaskCard.Parent = this.Container.TaskList;
					TaskCard.Visible = true;
					table.insert(this.Connections, TaskCardConnection);

					return TaskCard;
				end;

				-- Remove tasks that are no longer in the task scheduler
				for _, TaskCard in next, this.Container.TaskList:GetChildren() do
					if not TaskCard:IsA("TextButton") then continue end;

					if not Tasks[TaskCard.Name] then
						TaskCard:Destroy();

						if this.Constants.SelectedTask and (this.Constants.SelectedTask == TaskCard.Name) then
							this.Constants.SelectedTask = nil;
							ClearTaskMetadata();
						end;
					end;
				end;

				-- Add tasks that are not in the task scheduler
				for TaskName, Task in next, Tasks do
					if not Task.IsRecurringTask then continue end;
					
					if not this.Container.TaskList:FindFirstChild(Task.TaskName) then
						CreateTaskCard(Task.TaskName);
					end;
				end;
			end;

			local function UpdateSelectedTaskMetadata()
				if not this.Constants.SelectedTask then return end;
				if not TaskManager.TaskScheduler then return end;

				local SelectedTask = this.Constants.SelectedTask;
				local TaskData = TaskManager.TaskScheduler:GetTask(SelectedTask);
				
				if not TaskData then
					SelectedTask = nil;
					ClearTaskMetadata();
				return;
				end;
				
				local TaskMetadataContainer = this.Container.TaskMetadata;

				local function CreateTaskData(DataKey)
					local TaskDataObject = ObjectReferences.TaskDataReference:Clone();
					local TaskDataTitleObject = TaskDataObject:FindFirstChild("Title");

					TaskDataObject.Name = DataKey;
					TaskDataTitleObject.Text = DataKey;
					TaskDataObject.Parent = TaskMetadataContainer;
					TaskDataObject.Visible = true;
				end;

				-- Create all task data fields
				for DataName, DataValue in next, TaskData do
					if typeof(DataValue) == "function" then continue end;
					
					if not TaskMetadataContainer:FindFirstChild(DataName) then
						if DataValue == nil then continue end;
						
						CreateTaskData(DataName);
					end;
				end;

				-- Update all task data fields
				for DataName, DataValue in next, TaskData do
					-- Only update value if it is not a function
					if typeof(DataValue) == "function" then continue end;

					local DataValue = (typeof(DataValue) == "number" and math.round(DataValue) or DataValue);

					local TaskDataObject = TaskMetadataContainer:FindFirstChild(DataName);

					if TaskDataObject then
						TaskDataObject.Text = tostring(DataValue);
					end;
				end;
			end;

			UpdateTaskList();
			UpdateSelectedTaskMetadata();
		end;
	},
	["Performance"] = {
		Container = TaskManager.GUI.BodyContainer.PerformanceView.Container,
		Tab = TaskManager.GUI.TabContainer.Performance,
		Constants = {
			SelectedTask = nil,
		},
		Connections = {},

		UpdateFunction = function(this)
			local function ClearTaskMetadata()
				for _, TaskData in next, this.Container.TaskMetadata:GetChildren() do
					if not TaskData:IsA("TextLabel") then continue end;

					TaskData:Destroy();
				end;
			end;

			local function UpdateTaskList()
				if not TaskManager.TaskScheduler then return end;
				-- Get the tasks
				local Tasks = TaskManager.TaskScheduler.PerformanceManager.Tasks;

				-- Helper method for creating task cards
				local function CreateTaskCard(TaskName: string)
					local TaskCard = ObjectReferences.TaskCardReference:Clone();
					local TaskLabelObject = TaskCard:FindFirstChildWhichIsA("TextLabel");

					-- Hook into click event
					local TaskCardConnection = TaskCard.MouseButton1Click:Connect(function()
						this.Constants.SelectedTask = nil;
						ClearTaskMetadata();
						this.Constants.SelectedTask = TaskName;
					end);

					TaskLabelObject.Text = TaskName;
					TaskCard.Name = TaskName;
					TaskCard.Parent = this.Container.TaskList;
					TaskCard.Visible = true;
					table.insert(this.Connections, TaskCardConnection);

					return TaskCard;
				end;

				-- Remove tasks that are no longer in the task scheduler
				for _, TaskCard in next, this.Container.TaskList:GetChildren() do
					if not TaskCard:IsA("TextButton") then continue end;

					if not Tasks[TaskCard.Name] then
						TaskCard:Destroy();

						if this.Constants.SelectedTask and (this.Constants.SelectedTask == TaskCard.Name) then
							this.Constants.SelectedTask = nil;
							ClearTaskMetadata();
						end;
					end;
				end;

				-- Add tasks that are not in the task scheduler
				for TaskName, Task in next, Tasks do
					if not Task.IsRecurringTask then continue end;
					
					if not this.Container.TaskList:FindFirstChild(Task.TaskName) then
						CreateTaskCard(Task.TaskName);
					end;
				end;
			end;

			local function UpdateSelectedTaskMetadata()
				if not this.Constants.SelectedTask then return end;
				if not TaskManager.TaskScheduler then return end;

				local SelectedTask = this.Constants.SelectedTask;
				local TaskData = {};
				TaskData.AverageExecutionTime = TaskManager.TaskScheduler.PerformanceManager:GetTaskAverage(SelectedTask);
				TaskData.MaximumExecutionTime = TaskManager.TaskScheduler.PerformanceManager:GetTaskMaximum(SelectedTask);
				TaskData.DelayedExecutions = TaskManager.TaskScheduler.PerformanceManager:GetDelayedExecutionCount(SelectedTask);
				
				if not TaskData then
					SelectedTask = nil;
					ClearTaskMetadata();
				return;
				end;
				
				local TaskMetadataContainer = this.Container.TaskMetadata;

				local function CreateTaskData(DataKey)
					local TaskDataObject = ObjectReferences.TaskDataReference:Clone();
					local TaskDataTitleObject = TaskDataObject:FindFirstChild("Title");

					TaskDataObject.Name = DataKey;
					TaskDataTitleObject.Text = DataKey;
					TaskDataObject.Parent = TaskMetadataContainer;
					TaskDataObject.Visible = true;
				end;

				-- Create all task data fields
				for DataName, DataValue in next, TaskData do
					if (typeof(DataValue == "table") or typeof(DataValue) == "function") then continue end;
					
					if not TaskMetadataContainer:FindFirstChild(DataName) then
						if DataValue == nil then continue end;
						
						CreateTaskData(DataName);
					end;
				end;

				-- Update all task data fields
				for DataName, DataValue in next, TaskData do
					-- Only update value if it is not a function
					if (typeof(DataValue == "table") or typeof(DataValue) == "function") then continue end;

					local DataValue = (typeof(DataValue) == "number" and math.round(DataValue) or DataValue);

					local TaskDataObject = TaskMetadataContainer:FindFirstChild(DataName);

					if TaskDataObject then
						TaskDataObject.Text = tostring(DataValue);
					end;
				end;
			end;

			UpdateTaskList();
			UpdateSelectedTaskMetadata();
		end;
	},
	["Console"] = {
		Container = TaskManager.GUI.BodyContainer.ConsoleView.Container,
		Tab = TaskManager.GUI.TabContainer.Console,
		Constants = {
			LineCount = nil,
		},
		Connections = {},

		UpdateFunction = function(this)
			local MaxLineCount = 12; -- A constraint of the console size limit
			local CONSOLE_MAX_LIMIT = 500; -- The maximum amount of lines the console can hold
			local ConsoleLineReference = TaskManager.GUI.References.ConsoleLineReference:Clone();

			local function NewLine(LineText: string, OutputType: number?)
				local ConsoleLine = ConsoleLineReference:Clone();
				local TextSize = ConsoleLine.TextSize;
				local OutputType = (OutputType and math.clamp(OutputType, 1, 3) or nil);
				this.Constants.LineCount = math.min(this.Constants.LineCount + 1, CONSOLE_MAX_LIMIT);
				local CanvasSizeOffset = (this.Constants.LineCount > MaxLineCount and (TextSize * (this.Constants.LineCount - MaxLineCount)) or 0);

				local LineContainer = this.Container.TextContainer;

				if OutputType then
					if OutputType == 1 then
						ConsoleLine.TextColor3 = Color3.fromRGB(0, 255, 0);
						ConsoleLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
					elseif OutputType == 2 then
						ConsoleLine.TextColor3 = Color3.fromRGB(255, 255, 0);
						ConsoleLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
					elseif OutputType == 3 then
						ConsoleLine.TextColor3 = Color3.fromRGB(255, 0, 0);
						ConsoleLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
					end
				end;

				ConsoleLine.LayoutOrder = this.Constants.LineCount;
				ConsoleLine.Text = LineText;
				ConsoleLine.Parent = LineContainer;
				ConsoleLine.Visible = true;
				LineContainer.CanvasSize = UDim2.new(0, 0, 0.925, CanvasSizeOffset);

				-- Go to bottom of the console if we are at the top
				if (CanvasSizeOffset > 0) then
					LineContainer.CanvasPosition = Vector2.new(0, CanvasSizeOffset);
				end;

				-- Remove the first line if the console is over the limit
				if this.Constants.LineCount >= CONSOLE_MAX_LIMIT then
					local TopLineNumber = (this.Constants.LineCount - CONSOLE_MAX_LIMIT) + 1;

					for _, ConsoleLine in next, LineContainer:GetChildren() do
						if not ConsoleLine:IsA("TextLabel") then continue end;

						if ConsoleLine.LayoutOrder == TopLineNumber then
							ConsoleLine:Destroy();
						end;
					end;
				end;

				return ConsoleLine;
			end;

			local function ProcessParagraph(Paragraph: string)
				local Lines = {};

				for Line in Paragraph:gmatch("[^\r\n]+") do
					-- Remove trailing and leading spaces
					Line = Line:match("^%s*(.-)%s*$");
					-- Truncate empty lines / lines with only spaces
					if Line ~= "" then
						table.insert(Lines, Line);
					end;
				end;

				return Lines;
			end;

			local function DoConsoleOutput(Input: string, OutputType: number?)
				local Lines = ProcessParagraph(Input);

				for _, Line in next, Lines do
					NewLine(Line, OutputType);
				end;
			end;

			local function ClearConsole()
				local function ResetLineCount()
					this.Constants.LineCount = 0;
				end;

				for _, ConsoleLine in next, this.Container.TextContainer:GetChildren() do
					if not ConsoleLine:IsA("TextLabel") then continue end;

					ConsoleLine:Destroy();
				end;

				ResetLineCount()

				DoConsoleOutput([[
				Welcome to TaskManager Console
				--------------------------------
				To get started, type 'help' to see a list of commands
				--------------------------------
				]])
			end;

			local function ParseCommand(command)
				local parsedCommand = {}
    
				-- Split the command into tokens
				local tokens = {}
				for token in string.gmatch(command, "%S+") do
					table.insert(tokens, token)
				end
				
				-- Extract command name
				parsedCommand["command"] = tokens[1]
				
				-- Initialize options table
				parsedCommand["options"] = {}
				
				local i = 2
				while i <= #tokens do
					local option = tokens[i]
					local value = ""
					i = i + 1
					
					-- Check if the option starts with '-'
					if option:sub(1, 1) == "-" then
						-- Check if the option has a value
						if i <= #tokens and tokens[i]:sub(1, 1) ~= "-" then
							value = tokens[i]
							i = i + 1
						end
						
						-- Remove leading '-' from the option
						option = option:sub(2)
						
						-- Check if the option is followed by more options
						while i <= #tokens and tokens[i]:sub(1, 1) ~= "-" do
							value = value .. " " .. tokens[i]
							i = i + 1
						end
						
						-- Store the option and its value in the options table
						parsedCommand["options"][option] = value
					else
						-- If the token is not an option, consider it as an argument
						table.insert(parsedCommand, option)
					end
				end
				
				return parsedCommand
			end

			local function ProcessCommand(command, options)
				local Commands = {};

				Commands.help = {
					action = function()
						-- Aggregate all commands and their descriptions, and options
						local CommandList = {};
						for CommandName, CommandData in next, Commands do
							local CommandDescription = CommandData.description or "No description provided";
							local CommandOptions = CommandData.options or {};
							local CommandOptionString = "";

							for OptionName, OptionDescription in next, CommandOptions do
								CommandOptionString = CommandOptionString .. "\t -" .. OptionName .. ": " .. OptionDescription;
							end;

							table.insert(CommandList, CommandName .. ": " .. CommandDescription .. CommandOptionString);
						end;

						-- Concatenate all commands into a single string
						local CommandString = "";
						for _, Command in next, CommandList do
							CommandString = CommandString .. Command .. "\n";
						end;

						DoConsoleOutput(CommandString);
					end,
					description = "Display a list of commands",
					options = {}
				}

				Commands.clear = {
					action = function()
						ClearConsole();
					end,
					description = "Clear the console",
					options = {}
				}

				Commands.echo = {
					action = function(options)
						local Text = options.text or "No text provided";
						DoConsoleOutput(Text);
					end,
					description = "Echo text to the console",
					options = {
						t = "The text to echo"
					}
				}

				Commands.tab = {
					action = function(options)
						local TabName = options.name or "No name provided";
						local Tab = TaskManager.GUI.TabContainer:FindFirstChild(TabName);

						if not Tab then
							DoConsoleOutput("Tab not found");
						else
							Tab:FindFirstChildWhichIsA("TextButton"):Fire();
						end;

						return "Switched to tab " .. TabName;
					end,
					description = "Switch to a tab",
					options = {
						n = "The name of the tab"
					}
				}

				Commands.flush = {
					action = function(options)
						local OutputBuffer = TaskManager.TaskScheduler.Logger.OutputBuffer;

						-- Check options for amount of lines
						local LineCount = options.l and tonumber(options.l) or 100;

						if not options.s then
							for i = #OutputBuffer - LineCount, #OutputBuffer do
								local Log = OutputBuffer[i];
								if not Log then continue end;
								if options.m and (Log.Type ~= tonumber(options.m)) then continue end;
								DoConsoleOutput("[" .. os.date("%I:%M:%S %p", Log.Time) .. "] " .. Log.Message, Log.Type)
							end;

							return "Flushed " .. LineCount .. " lines";
						else
							local SearchString = options.s;
							local HitCount = 0;

							for i = 1, #OutputBuffer do
								if HitCount >= LineCount then break end;

								local Log = OutputBuffer[i];
								if not Log then continue end;
								if options.m and (Log.Type ~= tonumber(options.m)) then continue end;
								if string.find(string.lower(Log.Message), string.lower(SearchString)) then
									HitCount += 1;
									DoConsoleOutput("[" .. os.date("%I:%M:%S %p", Log.Time) .. "] " .. Log.Message, Log.Type);
								end;
							end;

							return "Flushed " .. tostring(HitCount) .. " logs containing '" .. SearchString .. "'";
						end;
					end,
					description = "Flush the output buffer",
					options = {
						l = "The amount of lines to flush",
						m = "The minimum log level to flush",
						s = "Search logs for string"
					}
				}

				Commands.clim = {
					action = function(options)
						local Limit = options.l and tonumber(options.l) or 500;
						CONSOLE_MAX_LIMIT = Limit;

						if not options.l then
							return "The current console limit is " .. Limit;
						end;

						return "Set the output limit to " .. Limit;
					end,
					description = "Set the output limit of the console",
					options = {
						l = "The limit to set"
					}
				}

				Commands.task = {
					action = function(options)
						local TaskName = options.n;
						local Task = TaskManager.TaskScheduler:GetTask(TaskName);

						if not Task then
							return "Task not found";
						end;

						if options.k then
							TaskManager.TaskScheduler:Deschedule(TaskName);
							return "Deschedule task " .. TaskName;
						elseif options.r then
							Task:Reset();
							return "Reset task " .. TaskName;
						elseif options.x then
							Task:Execute();
							return "Executed task " .. TaskName;
						elseif options.i then
							local TaskData = {};
							for DataName, DataValue in next, Task do
								TaskData[DataName] = DataValue;
							end;

							local TaskDataString = "";
							for DataName, DataValue in next, TaskData do
								TaskDataString = TaskDataString .. DataName .. ": " .. tostring(DataValue) .. "\n";
							end;

							return TaskDataString;
						end;

						return "No action specified";
					end,
					description = "Perform an action on a task",
					options = {
						n = "The name of the task",
						k = "Kill the task",
						r = "Reset the task",
						x = "Immediately execute the task",
						i = "Get information about the task"
					}
				}

				-- Begin command processing
				if not Commands[command] then
					return "Command not found";
				else
					local CommandData = Commands[string.lower(command)];
					local Success, Result = pcall(CommandData.action, options);

					if not Success then
						error("An error occurred while processing the command\n" .. Result, 0);
					else
						return Result;
					end;
				end
			end

			local function HookUserInput()
				local UserInput = this.Container.UserInput;
				local UserInputConnection;

				UserInputConnection = UserInput.FocusLost:Connect(function(EnterPressed)
					if not EnterPressed then return end;

					local Command = UserInput.Text;
					DoConsoleOutput(Owner.UserId .. "@rbx:~$ " .. Command);

					local ParsedCommand = ParseCommand(Command);
					if not ParsedCommand.command then 
						DoConsoleOutput("Invalid command.", 3)
					else
						local Success, ProcessedCommandOutput = pcall(ProcessCommand, ParsedCommand.command, ParsedCommand.options);

						if not Success then
							DoConsoleOutput("An error occurred while processing the command.\n" .. ProcessedCommandOutput, 3);
						elseif ProcessedCommandOutput and (ProcessedCommandOutput ~= "") then
							DoConsoleOutput(ProcessedCommandOutput);
						end;
					end;

					UserInput.Text = "";
				end);

				UserInput.PlaceholderText = Owner.UserId .. "@rbx:~$";
				table.insert(this.Connections, UserInputConnection);
			end;

			-- Console first run
			if not this.Constants.LineCount then
				ClearConsole();
				HookUserInput();
			end;
		end;
	},
	["Settings"] = {
		Container = TaskManager.GUI.BodyContainer.SettingsView.Container,
		Tab = TaskManager.GUI.TabContainer.Settings,
		Constants = {
		},
		Connections = {},

		UpdateFunction = function(this)
			local taskScheduler = TaskManager.TaskScheduler
			if not taskScheduler then return end
		
			local function UpdateSettingField(SettingName, SettingValue, SubTable)
				local SettingField = this.Container:FindFirstChild(SettingName)
				if not SettingField then return end
		
				local SettingFieldInput = SettingField:FindFirstChild(SettingValue and "Bool" or "Text")
		
				if SettingValue == nil then return end -- Handle cases where the setting value is nil
				
				SettingFieldInput.Text = SettingValue and "Enabled" or "Disabled"
			end
		
			local function CreateSettingField(SettingName, SettingValue, SubTable)
				if this.Container:FindFirstChild(SettingName) then return end
		
				local SettingField = ObjectReferences.SettingReference:Clone()
				local SettingType = type(SettingValue)
				local SettingFieldInput = SettingField:FindFirstChild(SettingType == "boolean" and "Bool" or "Text")
				if not SettingFieldInput then return end
		
				SettingField.Name = SettingName
				SettingField:FindFirstChild("Title").Text = SettingName
				SettingField:FindFirstChild("Title").Name = SubTable and SubTable or "TreeHead"
				SettingFieldInput.Text = SettingType == "boolean" and (SettingValue and "Enabled" or "Disabled") or tostring(SettingValue)
		
				-- Hook setting events
				local InputConnection
				if SettingType == "boolean" then
					InputConnection = SettingFieldInput.MouseButton1Click:Connect(function()
						local NewValue = not taskScheduler.Settings[SubTable and SubTable or SettingName]
						taskScheduler.Settings[SubTable and SubTable or SettingName] = NewValue
						UpdateSettingField(SettingName, NewValue, SubTable)
					end)
				else
					InputConnection = SettingFieldInput.FocusLost:Connect(function(EnterPressed)
						if not EnterPressed then return end
						local NewValue = SettingType == "number" and tonumber(SettingFieldInput.Text) or SettingFieldInput.Text
						taskScheduler.Settings[SubTable and SubTable or SettingName] = NewValue
						UpdateSettingField(SettingName, NewValue, SubTable)
					end)
				end
		
				table.insert(this.Connections, InputConnection)
				SettingField.Parent = this.Container
				SettingFieldInput.Visible = true
				SettingField.Visible = true
			end
		
			-- Create all settings fields
			for SettingName, SettingValue in pairs(taskScheduler.Settings) do
				if type(SettingValue) == "table" then
					for SubSettingName, SubSettingValue in pairs(SettingValue) do
						CreateSettingField(SubSettingName, SubSettingValue, SettingName)
					end
				else
					CreateSettingField(SettingName, SettingValue)
				end
			end
		
			-- Update all settings fields in case they have changed
			for SettingName, SettingValue in pairs(taskScheduler.Settings) do
				local SettingField = this.Container:FindFirstChild(SettingName)
				if not SettingField or SettingField.Text.IsFocused then continue end
		
				if type(SettingValue) == "table" then
					for SubSettingName, SubSettingValue in pairs(SettingValue) do
						UpdateSettingField(SubSettingName, SubSettingValue, SettingName)
					end
				else
					UpdateSettingField(SettingName, SettingValue)
				end
			end
		end
		
	}
}

-- Hook into buttons
TaskManager.HookTabButtons = function(this)
	for _, Tab in next, TaskManager.GUI.TabContainer:GetChildren() do
		if not Tab:IsA("Frame") then continue end;

		local TabButton = Tab:FindFirstChildWhichIsA("TextButton");

		TabButton.MouseButton1Click:Connect(function()
			-- Current Page
			local CurrentPage = this.ActivePage;
			local CurrentPageData = Pages[CurrentPage];

			-- Hide all pages
			for _, Page in next, Pages do
				Page.Container.Parent.Visible = false;
			end;

			-- Disconnect current page connections
			for _, Connection in next, CurrentPageData.Connections do
				Connection:Disconnect();
			end;

			-- Reset current page constants
			for index, Constant in next, CurrentPageData.Constants do
				CurrentPageData.Constants[index] = nil;
			end;
			
			Pages[Tab.Name].Container.Parent.Visible = true;
			this.ActivePage = Tab.Name;
		end)
	end;
end;

-- Update bottom bar
TaskManager.UpdateBottomBar = function(this)
	for MetadataKey, Metadata in next, BottomBarMetadata do
		Metadata:UpdateFunction();
	end;
end;

-- Initialize
TaskManager.Initialize = function(this, TaskScheduler)
	this.TaskScheduler = TaskScheduler;

	-- Initialize pages
	for _, Page in next, Pages do
		Page.Container.Parent.Visible = false;
	end;

	-- Activate TaskList page
	Pages["TaskList"].Container.Parent.Visible = true;
	this.ActivePage = "TaskList";
	
	this:HookTabButtons();
	return this;
end;

-- Update
TaskManager.Update = function(this)
	TaskManager:UpdateBottomBar();

	if this.ActivePage then
		Pages[this.ActivePage]:UpdateFunction();
	end;
end;

return TaskManager;