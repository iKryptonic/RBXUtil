local TaskScheduler = {
	OutputBuffer = {};
	TrackPerformance = true; -- Whether or not we're to use the performance tracking
	
	DebuggingEnabled = true; -- Whether or not debugging should be monitored
	
	Settings = { -- user preferences
		WarnLongThreadExecutions = true; -- Warn on long operation yielding?
		ThreadWarningThreshold = 12.5; -- Time in seconds to warn for operation yield

		KillRunawayTasks = true; -- Kill tasks that are spamming errors
		RunawayTaskThreshold = 50; -- Threshold for captured errors before a recurring thread is descheduled

		ErrorDebouncer = true; -- Use the error debouncing functions?
		ErrorDebounceTime = 2; -- Time to wait before sending a new error message
		ErrorExpireTime = 10; -- Time it takes for error messages to

		ThrottleThreadCreation = true; -- Set a maximum limit on threads created per-frame
		ThreadCreationThreshold = 2500; -- Maximum amount of threads to be created per-frame.
	};

	GenerateKey = nil;
	TaskSchedulerStep = nil;
	Schedule = nil;
	Deschedule = nil;
	Wait = nil;
}; 

local Tasks = {}; -- all tasks in queue
local KillList = {}; -- tasks meant to be descheduled
local FinishingEvents = {}; -- Events fired when a task is descheduled

-- formatting print, warn, error.
local function printf(s, ...)s=s:format(...)if not TaskScheduler.DebuggingEnabled then table.insert(TaskScheduler.OutputBuffer,{Type='print',Message=s,Time=os.time(),})else print(s)end end
local function warnf(s, ...)s=s:format(...)if not TaskScheduler.DebuggingEnabled then table.insert(TaskScheduler.OutputBuffer,{Type='warn',Message=s,Time=os.time(),})else warn(s)end end
local function errorf(s, ...)s=s:format(...)if not TaskScheduler.DebuggingEnabled then table.insert(TaskScheduler.OutputBuffer,{Type='error',Message=s,Time=os.time(),})else error(s, 0)end end

-- RunService and it's relevant members
local RunService = game:GetService("RunService");
local Stepped = RunService.Stepped;
local Heartbeat = RunService.Heartbeat;
local RenderStepped = RunService.RenderStepped;

local PerformanceManager = {}; do -- keeps track of runaway tasks (excessive errors)
	local Tasks = {};				-- and execution times for any task
	local ExecutionTimes = {};
	local DuplicateFrames = {};
	local TrackedErrors = {};

	function PerformanceManager:TaskBegin(TaskName)
		if not Tasks[TaskName] then
			Tasks[TaskName] = {};
		end
		Tasks[TaskName].StartTime = os.time() 
		Tasks[TaskName].EndTime = nil; 
		Tasks[TaskName].Running = true;
	end

	function PerformanceManager:TaskEnd(TaskName)
		if not ExecutionTimes[TaskName] then
			ExecutionTimes[TaskName] = {};
		end

		Tasks[TaskName].EndTime = os.time()
		Tasks[TaskName].Running = false;

		local ExecutionTime = (Tasks[TaskName].EndTime-Tasks[TaskName].StartTime)

		if #ExecutionTimes[TaskName] > 15 then
			table.remove(ExecutionTimes[TaskName], 1)
		end
		if TaskScheduler.Settings.WarnLongThreadExecutions then
			if TaskScheduler.Settings.ThreadWarningThreshold < ExecutionTime then
				warnf("TaskEnd - Long Thread Runtime [%s] - Ran for %d seconds. \n\t This is %d seconds longer than our set timer for %d", TaskName, ExecutionTime, ExecutionTime-TaskScheduler.Settings.ThreadWarningThreshold, TaskScheduler.Settings.ThreadWarningThreshold)
			end
		end
		Tasks[TaskName].LastExecution = ExecutionTime;
		table.insert(ExecutionTimes[TaskName], ExecutionTime)
	end

	function PerformanceManager:GetTaskAverage(TaskName)
		if TaskName and typeof(TaskName) == "string" and not ExecutionTimes[TaskName] then warnf("GetTaskAverage - Could not find Task %s", TaskName) return end
		local NumExecutions = #ExecutionTimes[TaskName];
		local TotalTime = 0;

		for _, Time in next, ExecutionTimes[TaskName] do
			TotalTime+=Time;
		end
		return TotalTime/NumExecutions;
	end

	function PerformanceManager:GetAllTasks()
		local Result = {};

		for TaskName, Data in pairs(Tasks) do
			if Data.Running or (os.time()-Data.EndTime) < 60 then
				Result[TaskName] = {Times=ExecutionTimes[TaskName],Data=Data,AverageExecutionTime=self:GetTaskAverage(TaskName)};
			end
		end
		return Result;
	end

	function PerformanceManager:GetTaskData(TaskName)
		return Tasks[TaskName], DuplicateFrames[TaskName], TrackedErrors[TaskName];
	end

	function PerformanceManager:LogDuplicateFrame(TaskName)
		if not DuplicateFrames[TaskName] then
			DuplicateFrames[TaskName] = 0;
		end
		DuplicateFrames[TaskName] += 1;
	end

	function PerformanceManager:TrackError(TaskName, ErrorText)
		if not TaskScheduler.Settings.ErrorDebouncer  then warn(ErrorText); warn(debug.traceback()) return end
		local frameTime = os.time()

		if not TrackedErrors[TaskName] then 
			TrackedErrors[TaskName] = {n=1};
		else
			TrackedErrors[TaskName].n += 1;

			if (TrackedErrors[TaskName].n % TaskScheduler.Settings.RunawayTaskThreshold/2) == 0 then
				TaskScheduler:Schedule(TaskScheduler:GenerateKey(), function()
					TrackedErrors[TaskName].n -= TaskScheduler.Settings.RunawayTaskThreshold/2;
				end, TaskScheduler.Settings.ErrorExpireTime, false, true)
			end
		end

		local ErrorTable = TrackedErrors[TaskName];

		if not ErrorTable.dt or ((frameTime-ErrorTable.dt) > TaskScheduler.Settings.ErrorDebounceTime) then
			TrackedErrors[TaskName].dt = frameTime;

			TrackedErrors[TaskName].traceback = debug.traceback();
			TrackedErrors[TaskName].error = ErrorText;

			warnf('TrackError - TASK [%s] EXCEPTION: %s (x%d)', TaskName, ErrorText, ErrorTable.n)
			if TaskScheduler.Settings.KillRunawayTasks and ErrorTable.n > TaskScheduler.Settings.RunawayTaskThreshold then
				local Task = self:GetTaskData(TaskName)
				if Task then
					TaskScheduler:Deschedule(TaskName, false)
					warnf("TrackError - Killed runaway task %s. (Task exceeded %d errors)", TaskName, TaskScheduler.Settings.RunawayTaskThreshold)
				end
			end
		end
	end
end

function TaskScheduler:ExecuteTask(Task, deltaTime)
	if Task then
		local index = table.find(KillList, Task.TaskName); -- Deschedule tasks marked for deletion
		if (index) then -- and table.remove(KillList, index)) then
			table.remove(Tasks, index)
			if FinishingEvents[Task.TaskName] then
				FinishingEvents[Task.TaskName]:Fire()
			end
			if not Task.Silent then
				warnf("TaskSchedulerStep - Task [%s] was descheduled.", Task.TaskName)
			end -- For tasks that are run in nested loops and aren't significant enough to warrant any feedback
			return -- move to next loop
		end

		if Task.TIME_REMAINING > 0 then
			Task.TIME_REMAINING -= deltaTime -- iterate the remaining time until execution by delta time provided by delta function
		else
			table.remove(Tasks, index); -- task is being run, remove its entry
			coroutine.wrap(function()
				if Task.Recurring then 
					-- Only log performance data for recurring tasks, non-recurring tasks
					-- are irrelevant because after one taskscheduler cycle they will be 
					-- handed off to a coroutine and have no impact on the next call to TaskName

					local PerformanceData = PerformanceManager:GetTaskData(Task.TaskName);
					-- Whenever a frame overlaps, log the data in the performance manager, 
					-- overlapping frames can be optimized to run with parallelism (AllowDuplicateFrames)
					-- or are a sign that a thread is running abnormally long and hogging frame space
					if PerformanceData and PerformanceData.Running and not Task.AllowDuplicateFrames then
						PerformanceManager:LogDuplicateFrame(Task.TaskName);
						--warnf('Task [%s] already has a running thread.. aborting', Task.TaskName)
						return; 
					end;

					-- If the previous iteration of the thread has completed execution,
					-- begin a new monitor for the current thread and the xpcall about
					-- to be executed within it.
					PerformanceManager:TaskBegin(Task.TaskName)
				end

				xpcall(Task.TaskFunction, function( Error ) 
					-- catch errors in performance manager so we can kill threads that
					-- are spamming errors and we can throttle how much spam is allowed inside
					-- the console e.g. "foo bar (x3)"
					PerformanceManager:TrackError(Task.TaskName, Error)
				end);

				if Task.Recurring then 
					-- Now we can allow the performancemanager to clear another instance of
					-- this task to be created on the next available frame.
					PerformanceManager:TaskEnd(Task.TaskName)
				end

				return
			end)()
			
			if Task.Recurring then 
				-- Schedule the next instance of the thread to be created on the next frame
				-- after the task has been run inside of the coroutine, move onto the next task.
				TaskScheduler:Schedule(Task.TaskName, Task.TaskFunction, Task.TaskDelay, Task.Recurring, Task.Silent, Task.AllowDuplicateFrames, true)
			end
		end
	end
end

function TaskScheduler.TaskSchedulerStep(dt)
	-- Task scheduler.
	local Threshold = TaskScheduler.Settings.ThreadCreationThreshold + (TaskScheduler.Settings.ThrottleThreadCreation and 1 or math.huge);
	
	for i = 1, Threshold do
		local Task = Tasks[i];
		
		if not Task then 
			-- No more tasks left.
			break;
		elseif (i > Threshold) then
			warnf("TaskSchedulerStep - %d threads staggered to next frame.", #Tasks-Threshold);
			break; -- offset the creation of new threads for the next available frame.
		end; -- This will yield our thread and return control back to the main thread instead of hogging CPU.

		local R, E = pcall(TaskScheduler.ExecuteTask, TaskScheduler, Task, dt);
		
		if not R then
			errorf("TaskSchedulerStep - An error has occurred while handling task %s, this is on our end.\n%s", Task.TaskName, E) -- this means a script error has occured, not a task error
		end -- This means an error occurred on our end. Sorry!
	end
end

function TaskScheduler:Schedule(TaskName, Task, TaskDelay, Recurring, Silent, AllowDuplicateFrames, Recurred)
	TaskDelay = (TaskDelay and TaskDelay or 0)

	if not Recurred and not Silent then
		if Recurring then
			warnf("Schedule - Scheduled recurring task [%s] %s%s", TaskName, (TaskDelay > 0) and " on timer - " .. tostring(TaskDelay) .. " seconds." or "", (AllowDuplicateFrames and " (DUPLICATE FRAMES ALLOWED)" or ""))
		else
			printf("Schedule - Scheduled task [%s] %s%s", TaskName, (TaskDelay > 0) and " on timer - " .. tostring(TaskDelay) .. " seconds." or "", (AllowDuplicateFrames and " (DUPLICATE FRAMES ALLOWED)" or ""))
		end
	end
	
	table.insert(Tasks, {
		TaskName=TaskName, 
		TaskDelay=TaskDelay, 
		TIME_REMAINING=TaskDelay, 
		TaskFunction=Task, 
		Recurring=Recurring, 
		Silent=Silent, 
		AllowDuplicateFrames=AllowDuplicateFrames, 
		Recurred=Recurred
	});
end;

function TaskScheduler:Deschedule(TaskName, Yield)
	local Bindable = Instance.new("BindableEvent");
	FinishingEvents[TaskName] = Bindable;
	table.insert(KillList, TaskName)
	if Yield then
		Bindable.Event:Wait();
	end;
end;

local i = 0;
local k = 256;
function TaskScheduler:GenerateKey(): any
	i += 1;
	return (os.time() % k) + i
end;

function TaskScheduler:GetTasks()
	if not RunService:IsStudio() then return end;

	return Tasks
end;

function TaskScheduler:GetPerformanceManager()
	if not RunService:IsStudio() then return end;

	return PerformanceManager
end;

return TaskScheduler;