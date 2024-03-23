--!strict
--[[
	TaskScheduler
	@Author: ikrypto
	@Date: 03-15-2024
]]

local TaskScheduler = {
	Tasks = {},
	OutputBuffer = {},
	FinishingEvents = {},

	Settings = {
		PerformanceManagerSettings = {
			WarnOnLongThreadExecutions = true,
			MaximumThreadWarningThreshold = 12.5,
			KillRunawayTasks = true,
			RunawayTaskThreshold = 50,
			ErrorDebouncerEnabled = true,
			ErrorDebounceTime = 1,
			ErrorExpireTime = 10
		},

		LoggerSettings = {
			DebuggingEnabled = false,
			MinimumLoggingLevel = 3,
		},

		ThrottleThreadCreation = true,
		ThreadCreationThreshold = 2500,
	},

	Logger = {
		Output = function(...)end
	},

	PerformanceManager = nil,
};

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Key Generation
local i = 0;
local k = 256;

-- Modules
local LoggerModule = require(script.Logger)
local PerformanceManagerModule = require(script.PerformanceManager)
local Task = require(script.Task)

-- Constants
local IsServer = RunService:IsServer();

function TaskScheduler.new(Settings)
	local Settings = Settings or TaskScheduler.Settings
	return setmetatable({   
		Tasks = {};
		Settings = Settings,
		Logger = LoggerModule,
		PerformanceManager = PerformanceManagerModule,
		Task = Task,
	}, TaskScheduler)
end

function TaskScheduler.Initialize(this)
	this.Logger:Initialize(this)
	this.PerformanceManager:Initialize(this)
	this.Task:Initialize(this)

	if IsServer then
		this:ExposeAPI()
	end;
end;

function TaskScheduler.ExecuteTask(this, Task: Task.Task)
	-- if task is marked for deletion, fire the finishing event and delete the task from list
	if Task.MarkedForDeletion then
		this.Tasks[Task.TaskName] = nil;

		if this.FinishingEvents[Task.TaskName] then
			this.FinishingEvents[Task.TaskName]:Fire()
		end

		if not Task.UseSilentOutput then
			this.Logger.Output(1, "TaskSchedulerStep - Task [%s] was descheduled.", Task.TaskName)
		end
		return;
	end

	-- Execute the task in a coroutine
	coroutine.wrap(function()
		if Task.IsRecurringTask then
			-- Log performance data for recurring tasks
			local PerformanceData = this.PerformanceManager:GetTaskData(Task.TaskName)
			if PerformanceData and PerformanceData.Running and not Task.AllowDuplicateFrames then
				this.PerformanceManager:LogDuplicateFrame(Task.TaskName)
				return
			end
			this.PerformanceManager:TaskBegin(Task.TaskName)
		end

		-- Execute the task function and catch errors
		xpcall(Task.TaskAction, function(Error)
			this.PerformanceManager:TrackError(Task.TaskName, Error)
		end)

		-- End tracking for recurring tasks
		if Task.IsRecurringTask then
			this.PerformanceManager:TaskEnd(Task.TaskName)
		end

		Task:UnlockEntity()
	end)()
end

-- Backwards compatibility
function TaskScheduler.Schedule(this, TaskName, Task, TaskDelay, Recurring, Silent, AllowDuplicateFrames, Recurred)
	this.ScheduleTask(
		{
			TaskName=TaskName,
			TaskAction=Task,
			TaskExecutionDelay=TaskDelay,
			IsRecurringTask=Recurring,
			UseSilentOutput=Silent,
			AllowDuplicateFrames=AllowDuplicateFrames
		}
	)
end

function TaskScheduler.ScheduleTask(this, Task: Task.Task)
	local TaskData: Task.Task = this.Task.new(Task)

	if (TaskData.IsRecurringTask) and
		(not TaskData.UseSilentOutput) then

		this.Logger.Output(1, "Schedule - Scheduled %s task [%s] %s%s", 
			(TaskData.IsRecurringTask and "recurring" or "non-recurring"),
			TaskData.TaskName, 
			(TaskData.TaskExecutionDelay > 0) and " on timer - " .. tostring(TaskData.TaskExecutionDelay) .. " seconds." or "", 
			(TaskData.AllowDuplicateFrames and " (DUPLICATE FRAMES ALLOWED)" or ""))
	end

	this.Tasks[TaskData.TaskName] = TaskData;
	return TaskData
end

function TaskScheduler.Deschedule(this, TaskName, Yield)
	if not this:GetTask(TaskName) then
		this.Logger.Output(3, "TaskScheduler: Task %s does not exist", TaskName)
		return;
	end

	local EventFinishingBindableEvent = Instance.new("BindableEvent")
	this.FinishingEvents[TaskName] = EventFinishingBindableEvent;

	this.Tasks[TaskName].RemainingTimeToExecution = 0;
	this.Tasks[TaskName].MarkedForDeletion = true; -- cleanup during execution
	this.Tasks[TaskName].Locked = false; -- unlock task

	if Yield then
		EventFinishingBindableEvent.Event:Wait()
	end
end

function TaskScheduler.TaskSchedulerStep(this, DeltaTimeSinceLastStep)
	local Threshold = this.Settings.ThreadCreationThreshold + (this.Settings.ThrottleThreadCreation and 1 or math.huge)

	for TaskName, Task: Task.Task in next, this.Tasks do
		if Task.Locked then
			continue 
		end -- avoid getting errors from locked tasks

		if (Task.TaskRemainingTimeToExecution <= 0) then 
			if (Threshold <= 0) then
				continue;
			end

			Threshold -= 1;
			Task:Execute()
		else
			Task:Step(DeltaTimeSinceLastStep)
		end
	end

	if Threshold <= 0 then
		this.Logger.Output(2, "TaskScheduler: Skipped task execution due to throttle")
	end
end

function TaskScheduler.GenerateKey(this)
	i += 1;
	return (os.clock() % k) + i
end

function TaskScheduler.GetTaskCount(this)
	local Count = 0;
	for _, _ in next, this.Tasks do
		Count += 1;
	end
	return Count;
end

function TaskScheduler.ClearTasks(this)
	for TaskName, Task: Task.Task in next, this.Tasks do
		this:Deschedule(TaskName, false)
	end
	repeat task.wait() until this:GetTaskCount() == 0;

	this.Logger.Output(1, "TaskScheduler: All tasks have been descheduled")
end

function TaskScheduler.GetTask(this, TaskName)
	return this.Tasks[TaskName];
end

function TaskScheduler.ExposeAPI(this)
	local ServerMessageReceiver = Instance.new("BindableEvent");
	local ServerFunction = Instance.new("BindableFunction");
	local ClientMessageReceiver = Instance.new("RemoteEvent");
	local ClientFunction = Instance.new("RemoteFunction");

	ServerMessageReceiver.Name = "TaskSchedulerServerMessageReceiver";
	ServerFunction.Name = "TaskSchedulerServerFunction";
	ClientMessageReceiver.Name = "TaskSchedulerClientMessageReceiver";
	ClientFunction.Name = "TaskSchedulerClientFunction";

	ServerMessageReceiver.Parent = ReplicatedStorage;
	ServerFunction.Parent = ReplicatedStorage;
	ClientMessageReceiver.Parent = ReplicatedStorage;
	ClientFunction.Parent = ReplicatedStorage;

	local function HandleMessage(Message: string, ...: any)
		local Arguments = {...};

		-- Handle messages
		if Message == "Deschedule" then
			return this:Deschedule(Arguments[1], Arguments[2])
		elseif Message == "GetTasks" then
			return this.Tasks
		elseif Message == "GetLogs" then
			return this.Logger.OutputBuffer
		elseif Message == "GetSettings" then
			return this.Settings
		elseif Message == "SetSetting" then
			if #Arguments == 3 then
				this.Settings[Arguments[1]][Arguments[2]] = Arguments[3]
			else
				this.Settings[Arguments[1]] = Arguments[2]
			end
		elseif Message == "PerformanceManager" then
			if Arguments[1] == "GetTaskAverage" then
				return this.PerformanceManager:GetTaskAverage(Arguments[2])
			elseif Arguments[1] == "GetTaskMaximum" then
				return this.PerformanceManager:GetTaskMaximum(Arguments[2])
			elseif Arguments[1] == "GetDelayedExecutionCount" then
				return this.PerformanceManager:GetDelayedExecutionCount(Arguments[2])
			elseif Arguments[1] == "GetActiveTasks" then
				return this.PerformanceManager:GetActiveTasks()
			elseif Arguments[1] == "GetTasks" then
				return this.PerformanceManager.Tasks
			end
		end
	end

	ServerMessageReceiver.Event:Connect(function(Player, Message, ...)
		HandleMessage(Message, ...)
	end)

	ServerFunction.OnInvoke = function(Player, Message, ...)
		return HandleMessage(Message, ...)
	end

	ClientMessageReceiver.OnServerEvent:Connect(function(Player, Message, ...)
		HandleMessage(Message, ...)
	end)

	ClientFunction.OnServerInvoke = function(Player, Message, ...)
		return HandleMessage(Message, ...)
	end
end

-- Metatable indexes for TaskScheduler
function TaskScheduler.__index(this, index)
	if TaskScheduler[index] then
		return TaskScheduler[index];
	else
		return this.Tasks[index];
	end
end

function TaskScheduler.__newindex(this, key, value)
	if TaskScheduler[key] then
		error("Cannot modify a read-only table", 0)
	else
		this:Schedule()
	end
end

function TaskScheduler.__call(this, Task)
	return this:Schedule(Task)
end

function TaskScheduler.__metatable()
	return "The metatable is locked";
end

function TaskScheduler.__tostring()
	return "TaskScheduler";
end

return TaskScheduler;