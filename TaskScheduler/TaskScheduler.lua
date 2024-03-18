--!strict
--[[
	TaskScheduler
	@Author: ikrypto
	@Date: 03-15-2024

	Methods:
		Step method
		Schedule method
		Unschedule method
		Task execution method
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
		Output = function(...)end;
	},
	PerformanceManager = nil,
};

-- Key Generation
local i = 0;
local k = 256;

-- Modules
local LoggerModule = require(script.Logger);
local PerformanceManagerModule = require(script.PerformanceManager);
local Task = require(script.Task)

function TaskScheduler.new(Settings)
	return setmetatable({   
		Tasks = {};
		Settings = Settings,
		Logger = LoggerModule,
		PerformanceManager = PerformanceManagerModule,
		Task = Task,
	}, TaskScheduler);
end

function TaskScheduler.Initialize(this)
	this.Logger:Initialize(this);
	this.PerformanceManager:Initialize(this);
	this.Task:Initialize(this);
end

function TaskScheduler.ExecuteTask(this, TaskData: Task.Task)
	-- if task is marked for deletion, fire the finishing event and delete the task from list
	if TaskData.MarkedForDeletion then
		this.Tasks[TaskData.TaskName] = nil;

		if this.FinishingEvents[TaskData.TaskName] then
			this.FinishingEvents[TaskData.TaskName]:Fire();
		end;

		if not TaskData.UseSilentOutput then
			this.Logger.Output(2, "TaskSchedulerStep - Task [%s] was descheduled.", TaskData.TaskName)
		end;
		return;
	end;

	-- Execute the task in a coroutine
	coroutine.wrap(function()
		if TaskData.IsRecurringTask then
			-- Log performance data for recurring tasks
			local PerformanceData = this.PerformanceManager:GetTaskData(TaskData.TaskName)
			if PerformanceData and PerformanceData.Running and not TaskData.AllowDuplicateFrames then
				this.PerformanceManager:LogDuplicateFrame(TaskData.TaskName)
				return
			end
			this.PerformanceManager:TaskBegin(TaskData.TaskName)
		end

		-- Execute the task function and catch errors
		xpcall(TaskData.TaskAction, function(Error)
			this.PerformanceManager:TrackError(TaskData.TaskName, Error)
		end)

		-- End tracking for recurring tasks
		if TaskData.IsRecurringTask then
			this.PerformanceManager:TaskEnd(TaskData.TaskName)
		end

		TaskData:UnlockEntity();
	end)();
end;

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

function TaskScheduler.ScheduleTask(this, TaskData: Task.Task)
	local TaskMetadata: Task.Task = this.Task.new(TaskData);

	if (TaskMetadata.IsRecurringTask) and
		(not TaskMetadata.UseSilentOutput) then

		this.Logger.Output(2, "Schedule - Scheduled %s task [%s] %s%s", 
			(TaskMetadata.IsRecurringTask and "recurring" or "non-recurring"),
			TaskMetadata.TaskName, 
			(TaskMetadata.TaskExecutionDelay > 0) and " on timer - " .. tostring(TaskMetadata.TaskExecutionDelay) .. " seconds." or "", 
			(TaskMetadata.AllowDuplicateFrames and " (DUPLICATE FRAMES ALLOWED)" or ""));
	end;

	this.Tasks[TaskMetadata.TaskName] = TaskMetadata;
	return TaskMetadata
end

function TaskScheduler.Deschedule(this, TaskName, Yield)
	if not this.Tasks[TaskName] then
		this.Logger.Output(3, "TaskScheduler: Task %s does not exist", TaskName);
		return;
	end;

	local EventFinishingBindableEvent = Instance.new("BindableEvent");
	this.FinishingEvents[TaskName] = EventFinishingBindableEvent;

	this.Tasks[TaskName].RemainingTimeToExecution = 0;
	this.Tasks[TaskName].MarkedForDeletion = true; -- cleanup during execution
	this.Tasks[TaskName].Locked = false; -- unlock task

	if Yield then
		EventFinishingBindableEvent.Event:Wait();
	end;
end;

function TaskScheduler.TaskSchedulerStep(this, DeltaTimeSinceLastStep)
	local Threshold = this.Settings.ThreadCreationThreshold + (this.Settings.ThrottleThreadCreation and 1 or math.huge);

	for TaskName, Task: Task.Task in next, this.Tasks do
		if Task.Locked then
			continue 
		end; -- avoid getting errors from locked tasks

		if (Task.TaskRemainingTimeToExecution <= 0) then 
			if (Threshold <= 0) then
				continue;
			end;

			Threshold -= 1;
			Task:Execute();
		else
			Task:Step(DeltaTimeSinceLastStep);
		end;
	end;

	if Threshold <= 0 then
		this.Logger.Output(2, "TaskScheduler: Skipped task execution due to throttle");
	end;
end;

function TaskScheduler.GenerateKey(this)
	i += 1;
	return (os.time() % k) + i
end;

function TaskScheduler.GetTaskCount(this)
	local Count = 0;
	for _, _ in next, this.Tasks do
		Count += 1;
	end;
	return Count;
end;

function TaskScheduler.ClearTasks(this)
	for TaskName, Task: Task.Task in next, this.Tasks do
		this:Deschedule(TaskName, false);
	end;
	repeat task.wait() until this:GetTaskCount() == 0;

	this.Logger.Output(2, "TaskScheduler: All tasks have been descheduled");
end;

function TaskScheduler.GetTask(this, TaskName)
	return this.Tasks[TaskName];
end;

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
		error("Cannot modify a read-only table");
	else
		this:Schedule();
	end
end

function TaskScheduler.__call(this, TaskData)
	return this:Schedule(TaskData);
end

function TaskScheduler.__metatable()
	return "The metatable is locked";
end

function TaskScheduler.__tostring()
	return "TaskScheduler";
end

return TaskScheduler;