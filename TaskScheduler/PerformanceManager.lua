--!nonstrict
--[[ 
    PerformanceManager.lua
    @Author: ikrypto
    @Date: 03-15-2024
]]

local PerformanceManager = {
	-- Data structures to store task-related information
	Tasks = {};
	TaskExecutionRunningTimeList = {};
	DelayedTaskExecutions = {};
	TaskDuplicateFrameList = {};
	TrackedErrorList = {};

	-- Settings for the PerformanceManager (Overriden on init)
	Settings = {
		WarnOnLongThreadExecutions = true; 
		MaximumThreadWarningThreshold = 12.5; 

		KillRunawayTasks = true; 
		RunawayTaskThreshold = 50; 

		ErrorDebouncerEnabled = true; 
		ErrorDebounceTime = 1; 
		ErrorExpireTime = 10; 
	};

	-- References to external modules
	TaskScheduler = nil;
	Logger = nil;
}

--[[ 
    Initializes the PerformanceManager.
    @param TaskScheduler (object): An object representing the task scheduler.
--]]
PerformanceManager.Initialize = function(this, TaskScheduler)
	-- Set references to external modules
	this.TaskScheduler = TaskScheduler
	this.Settings = TaskScheduler.Settings.PerformanceManagerSettings or this.Settings
	this.Logger = TaskScheduler.Logger

	return this;
end

--[[ 
    Begins tracking the execution time of a task.
    @param TaskName (string): The name of the task.
--]]
PerformanceManager.TaskBegin = function(this, TaskName, TaskData)
	-- Initialize task data
	this.Tasks[TaskName] = {
		TaskStartTime = os.clock(),
		TaskEndTime = nil,
		IsTaskRunning = true,
		TaskData = table.clone(TaskData)
	}
end

--[[ 
    Ends tracking the execution time of a task and calculates its duration.
    @param TaskName (string): The name of the task.
--]]
PerformanceManager.TaskEnd = function(this, TaskName)
	this.TaskExecutionRunningTimeList[TaskName] = this.TaskExecutionRunningTimeList[TaskName] or {}
	-- Fetch task details
	local Task = this.Tasks[TaskName]

	-- Record end time and mark task as not running
	Task.TaskEndTime = os.clock()
	Task.IsTaskRunning = false

	-- Retrieve or initialize running time list for the task
	local RunningTimeList = this.TaskExecutionRunningTimeList[TaskName] or {}

	-- Calculate duration of task execution
	local DeltaTimeToExecuteTask = Task.TaskEndTime - Task.TaskStartTime

	-- Remove oldest entry if list exceeds a certain length
	if #RunningTimeList > 15 then
		table.remove(RunningTimeList, 1)
	end

	-- Add current execution time to the list
	table.insert(RunningTimeList, DeltaTimeToExecuteTask)
	this.TaskExecutionRunningTimeList[TaskName] = RunningTimeList

	-- Check for long thread execution
	local MaxWarningThreshold = this.Settings.MaximumThreadWarningThreshold

	if this.Settings.WarnOnLongThreadExecutions and (MaxWarningThreshold < DeltaTimeToExecuteTask) then
		local ExceededThreshold = DeltaTimeToExecuteTask - MaxWarningThreshold
		this.Logger.Output(2, "TaskEnd - Long Thread Runtime [%s] - Ran for %d seconds. \n\t This is %d seconds longer than our set timer for %d", TaskName, DeltaTimeToExecuteTask, ExceededThreshold, MaxWarningThreshold)
	end

	-- Record the last execution time of the task
	Task.LastTaskExecutionTime = DeltaTimeToExecuteTask
end

--[[ 
    Computes the average execution time of a task.
    @param TaskName (string): The name of the task.
    @return (number): The average execution time.
--]]
PerformanceManager.GetTaskAverage = function(this, TaskName)
	this.TaskExecutionRunningTimeList[TaskName] = this.TaskExecutionRunningTimeList[TaskName] or {}
	-- Retrieve execution times for the task
	local ExecutionTimes = this.TaskExecutionRunningTimeList[TaskName]

	-- If no execution times are found, print a warning and return nil
	if not ExecutionTimes then
		this.Logger.Output(2, "GetTaskAverage - Could not find Task %s", TaskName)
		return
	end

	-- Calculate the total time taken by summing all execution times
	local TotalTime = 0
	for _, Time in ipairs(ExecutionTimes) do
		TotalTime = TotalTime + Time
	end

	-- Calculate and return the average execution time
	return TotalTime / #ExecutionTimes
end

--[[ 
    Retrieves information about all active tasks.
    @return (table): A table containing information about active tasks.
--]]
PerformanceManager.GetActiveTasks = function(this)
	-- Initialize an empty table to store the result
	local Result = {}

	-- Iterate over all tasks
	for TaskName, Data in pairs(this.Tasks) do
		-- Check if the task is running or has recently finished (within 60 seconds)
		if Data.IsTaskRunning then
			-- Add information about the task to the result table
			Result[TaskName] = {
				Times = this.TaskExecutionRunningTimeList[TaskName] or {}, -- Execution times
				Data = Data, -- Task data
				AverageExecutionTime = this:GetTaskAverage(TaskName) -- Average execution time
			}
		end
	end

	-- Return the result table containing information about active tasks
	return Result
end

--[[
	Retrieves information about all delayed task executions.
	@return (table): A table containing information about delayed task executions.
]]
PerformanceManager.GetDelayedTaskExecutions = function(this)
	-- Initialize an empty table to store the result
	local Result = {}

	-- Iterate over all delayed task executions
	for TaskName, DelayedExecutionList in pairs(this.DelayedTaskExecutions) do
		-- Add information about the delayed task executions to the result table
		Result[TaskName] = DelayedExecutionList
	end

	-- Return the result table containing information about delayed task executions
	return Result
end

--[[ 
	Retrieves information about all tracked errors.
	@return (table): A table containing information about tracked errors.
--]]
PerformanceManager.GetTrackedErrors = function(this)
	-- Initialize an empty table to store the result
	local Result = {}

	-- Iterate over all tracked errors
	for TaskName, ErrorData in pairs(this.TrackedErrorList) do
		-- Add information about the tracked errors to the result table
		Result[TaskName] = ErrorData
	end

	-- Return the result table containing information about tracked errors
	return Result
end

--[[ 
	Retrieves information about a specific task.
	@param TaskName (string): The name of the task.
	@return (table): Information about the task such as errors, delayed executions, etc.
--]]
PerformanceManager.GetTask = function(this, TaskName)
	-- Initialize an empty table to store the result
	local Result = {}

	-- Add information about the task to the result table
	Result.TaskData = this.Tasks[TaskName]
	Result.DuplicateFrames = this.TaskDuplicateFrameList[TaskName]
	Result.TrackedErrors = this.TrackedErrorList[TaskName]
	Result.AverageExecutionTime = this:GetTaskAverage(TaskName)

	-- Return the result table containing information about the task
	return Result
end

--[[ 
    Retrieves data associated with a specific task.
    @param TaskName (string): The name of the task.
    @return (table): Information about the task, duplicate frames, and tracked errors.
--]]
PerformanceManager.GetTaskData = function(this, TaskName)
	return this.Tasks[TaskName]
end

--[[ 
    Increments the count of duplicate frames for a task.
    @param TaskName (string): The name of the task.
--]]
PerformanceManager.LogDuplicateFrame = function(this, TaskName)
	-- Increment the count of duplicate frames for the task and log the time the duplicate frame occurred
	local DuplicateFrameEntry = {
		Time = tick()
	} 

	-- Initialize the duplicate frame list if it doesn't exist
	this.TaskDuplicateFrameList[TaskName] = this.TaskDuplicateFrameList[TaskName] or {}

	-- Add the entry to the list of duplicate frames
	table.insert(this.TaskDuplicateFrameList, DuplicateFrameEntry)
end

--[[
    Logs delayed execution of a task.
    @param TaskName (string): The name of the task.
    @param Delay (number): The delay in seconds.
]]
PerformanceManager.LogDelayedExecution = function(this, TaskName, Delay)
	-- Create new entry for task logging time which we hit the delay as well as the delay itself
	local DelayedExecutionEntry = {
		Delay = Delay,
		Time = tick()
	}

	-- Initialize the delayed task execution list if it doesn't exist
	this.DelayedTaskExecutions[TaskName] = this.DelayedTaskExecutions[TaskName] or {}

	-- Add the entry to the list of delayed task executions
	table.insert(this.DelayedTaskExecutions, DelayedExecutionEntry)
end

--[[ 
    Tracks errors encountered during task execution.
    @param TaskName (string): The name of the task.
    @param ErrorText (string): The error message.
--]]
PerformanceManager.TrackError = function(this, TaskName, ErrorText)
	-- Check if error debouncer is disabled
	if not this.Settings.ErrorDebouncerEnabled then
		-- Print the error message and stack trace
		this.Logger.Output(3, ErrorText)
		this.Logger.Output(2, debug.traceback())
		return
	end

	-- Get current time
	local FrameTime = tick()

	-- Initialize error tracking table for the task if not present
	this.TrackedErrorList[TaskName] = this.TrackedErrorList[TaskName] or { n = 0, dt = 0 }
	local ErrorTable = this.TrackedErrorList[TaskName]

	-- Increment error count for the task
	ErrorTable.n = ErrorTable.n + 1

	-- Check if error count exceeds the threshold for runaway tasks
	if ErrorTable.n >= this.Settings.RunawayTaskThreshold then
		-- Schedule a task to decrement error count after a specified delay
		this.TaskScheduler:ScheduleTask({TaskName=this.TaskScheduler:GenerateKey(), 
			TaskExecutionDelay=this.Settings.ErrorExpireTime,
			TaskAction=function()
				ErrorTable.n = ErrorTable.n - this.Settings.RunawayTaskThreshold
			end}
		)
	end

	-- Check if it's time to log the error and if it's not a duplicate error
	if not ErrorTable.dt or ((FrameTime - ErrorTable.dt) > this.Settings.ErrorDebounceTime) then
		-- Update error tracking table with error details
		ErrorTable.dt = FrameTime
		ErrorTable.traceback = debug.traceback()
		ErrorTable.error = ErrorText

		-- Print the error message with task name and error count
		this.Logger.Output(3, 'TrackError - TASK [%s] EXCEPTION: %s (x%d)', TaskName, ErrorText, ErrorTable.n)

		-- Check if runaway tasks should be killed and if the error count exceeds the threshold
		if this.Settings.KillRunawayTasks and ErrorTable.n > this.Settings.RunawayTaskThreshold then
			-- Get task data and deschedule the task if found
			local Task = this:GetTaskData(TaskName)
			if Task then
				this.TaskScheduler:Deschedule(TaskName)
				this.Logger.Output(2, "TrackError - Killed runaway task %s. (Task exceeded %d errors)", TaskName, this.Settings.RunawayTaskThreshold)
			end
		end
	end
end

return PerformanceManager