--!strict
--[[ 
    Task.lua
    @Author: ikrypto
    @Date: 03-15-2024
]]

export type Task = {
	TaskName: string,
	TaskAction: any,
	TaskExecutionDelay: number,
	TaskRemainingTimeToExecution: number,
	IsRecurringTask: boolean?,
	UseSilentOutput: boolean?,
	AllowDuplicateFrames: boolean?,
	MarkedForDeletion: boolean,
	Locked: boolean,
	CallingScript: string?,
	Reset: (Task) -> (),
	LockEntity: (Task) -> (),
	UnlockEntity: (Task) -> (),
	Step: (Task, number) -> (),
	Execute: (Task) -> (any)
}

local Task = {
	TaskScheduler = {
		ExecuteTask = function(...)end
	},
	Logger = {
		Output = function(...)end
	},
}

function Task.Initialize(this, TaskScheduler)
	this.TaskScheduler = TaskScheduler
	this.Logger = TaskScheduler.Logger
end

function Task.new(TaskData)
	local newTask: Task = {
		-- mutable task attributes
		TaskName = TaskData.TaskName,
		TaskAction = TaskData.TaskAction,
		TaskExecutionDelay = TaskData.TaskExecutionDelay,
		TaskRemainingTimeToExecution = TaskData.TaskExecutionDelay,
		IsRecurringTask = TaskData.IsRecurringTask,
		UseSilentOutput = TaskData.UseSilentOutput,
		AllowDuplicateFrames = TaskData.AllowDuplicateFrames,
		CallingScript = (getfenv(3).script and getfenv(3).script.Name or "Unknown"),

		-- Begin static task attributes
		MarkedForDeletion = false, -- Marked to be deleted on next task execution
		Locked = false, -- Currently handled by ExecuteTask

		-- immutable task attributes
		Reset = function(this: Task)
			this.TaskRemainingTimeToExecution = this.TaskExecutionDelay
		end,

		LockEntity = function(this: Task)
			this.Locked = true
		end,

		UnlockEntity = function(this: Task)
			this.Locked = false
		end,

		Step = function(this: Task, DeltaTimeSinceLastStep)
			if this.Locked then
				Task.Logger.Output(3, "TaskScheduler: Task %s is currently locked and cannot be stepped.", this.TaskName)
				return
			end

			this.TaskRemainingTimeToExecution = this.TaskRemainingTimeToExecution - DeltaTimeSinceLastStep
		end,

		Execute = function(this:Task)
			if this.Locked then
				Task.Logger.Output(3, "TaskScheduler: Task %s is currently locked and cannot be executed.", this.TaskName)
				return
			end

			this:LockEntity()
			this:Reset()

			local TaskWrapperSuccess: boolean, TaskWrapperReturnedValue: string? = pcall(Task.TaskScheduler.ExecuteTask, Task.TaskScheduler, this)

			if not TaskWrapperSuccess then
				Task.Logger.Output(3, "TaskScheduler: An error has occurred while handling task %s: %s", this.TaskName, TaskWrapperReturnedValue)
			end

			if not this.IsRecurringTask then
				this.MarkedForDeletion = true;
			end

			return TaskWrapperReturnedValue
		end,
	}

	return newTask
end

return Task