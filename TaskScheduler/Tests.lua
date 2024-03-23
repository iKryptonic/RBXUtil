--[[
    Tests.lua
	@Author: ikrypto
	@Date: 03-19-2024
]]

local TaskSchedulerModule = require(script.TaskScheduler)
local RunService = game:GetService("RunService")

local TestSuccessCount = 0;
local ErrorMarginUpperLimit = 0.05

local DefaultSettings = {
	PerformanceManagerSettings = {
		WarnOnLongThreadExecutions = true,
		MaximumThreadWarningThreshold = 12.5,
		KillRunawayTasks = true,
		RunawayTaskThreshold = 5,
		ErrorDebouncerEnabled = true,
		ErrorDebounceTime = 1,
		ErrorExpireTime = 10
	},

	LoggerSettings = {
		DebuggingEnabled = true,
		MinimumLoggingLevel = 3,
	},

	ThrottleThreadCreation = true,
	ThreadCreationThreshold = 2500,
}


local function RunTest(TaskSchedulerInstance, TestName, TestFunction, runParallel)
	local function RunTestFunction()
		local StartTime = tick()
		local Success, Error = pcall(TestFunction, TaskSchedulerInstance)
		local EndTime = tick()
		local TimeTaken = EndTime - StartTime

		if Success then
			--print(string.format("Test %s passed in %f seconds", TestName, TimeTaken))
			TestSuccessCount = TestSuccessCount + 1;
		else
			warn(string.format("Test %s failed in %f seconds with error: %s", TestName, TimeTaken, Error))
		end
	end

	if runParallel then
		coroutine.wrap(RunTestFunction)()
	else
		RunTestFunction()
		--repeat wait() until not TaskScheduler:GetTask(TestName)
	end
end

local function RunTestSuite(testSuite)
	local taskScheduler = TaskSchedulerModule.new(DefaultSettings)
	taskScheduler.Initialize(taskScheduler)
	shared.TaskScheduler = taskScheduler
	
	RunService.Heartbeat:Connect(function(deltaTime)
		taskScheduler:TaskSchedulerStep(deltaTime)
	end)

	for _, testConfig in pairs(testSuite) do
		if testConfig.parallelizeRun then 
			continue; 
		end;
		RunTest(taskScheduler, 
			testConfig.testName, 
			testConfig.testFunction, 
			testConfig.parallelizeRun)
	end
	for _, testConfig in pairs(testSuite) do
		if not testConfig.parallelizeRun then 
			continue; 
		end;
		RunTest(taskScheduler, 
			testConfig.testName, 
			testConfig.testFunction, 
			testConfig.parallelizeRun)
	end

	repeat task.wait() until taskScheduler:GetTaskCount() == 0

	print(string.format("Test suite completed with %d/%d tests passed", TestSuccessCount, #testSuite))
end

local function AddTestWithControl(testName, testFunction, schedulerSettings, parallelizeRun)
	return {
		testFunction = testFunction,
		schedulerSettings = schedulerSettings,
		testName = testName,
		parallelizeRun = parallelizeRun
	}
end

local function FindLogResult(logger, stringToMatch)
	local function CheckForString()
		for _, log in pairs(logger.OutputBuffer) do
			if string.find(log.Message, stringToMatch) then
				return log.Message
			end
		end
		return false
	end

	repeat task.wait() until CheckForString()

	return CheckForString()
end

-- Tests
local testingSuite = {
	-- Schedule a task to run in 5 seconds
	AddTestWithControl("ScheduleTask", function(TaskScheduler)
		TaskScheduler:ScheduleTask({
			TaskName = "ScheduleTask",
			UseSilentOutput = false,
			TaskExecutionDelay = 5,
			TaskAction = function()
				print("[ScheduleTask] Task ran after 5 seconds")
			end
		})
	end, {}, true),

	-- Schedule a task to run in 5 seconds and cancel it
	AddTestWithControl("CancelTask", function(TaskScheduler)
		local DidRun = false;
		
		local TaskId = TaskScheduler:ScheduleTask({
			TaskName = "CancelTask",
			UseSilentOutput = false,
			TaskExecutionDelay = 5,
			TaskAction = function()
				DidRun = true;
				error("[CancelTask] Should not have been executed", 0)
			end
		})

		TaskScheduler:Deschedule("CancelTask")

		task.wait(8)
		if TaskScheduler:GetTask("CancelTask") then
			error("[CancelTask] Task was not successfully descheduled", 0)
		else
			print("[CancelTask] Task was successfully descheduled")
		end
	end, {}, false),	

	-- Test task descheduling and rescheduling
	AddTestWithControl("DescheduleReschedule", function(TaskScheduler)
		local taskExecuted = false

		local taskId = TaskScheduler:ScheduleTask({
			TaskName = "DescheduleRescheduleTask",
			UseSilentOutput = false,
			TaskExecutionDelay = 5,
			TaskAction = function()
				taskExecuted = true
			end
		})

		TaskScheduler:Deschedule("DescheduleRescheduleTask")

		task.wait(6)

		if not taskExecuted then
			--print("[DescheduleReschedule] Task successfully descheduled")
		else
			error("[DescheduleReschedule] Task execution after descheduling")
		end

		TaskScheduler:ScheduleTask({
			TaskName = "DescheduleRescheduleTask",
			UseSilentOutput = false,
			TaskExecutionDelay = 0,
			TaskAction = function()
				taskExecuted = true
			end
		})

		task.wait(0.2)

		if taskExecuted then
			print("[DescheduleReschedule] Task successfully rescheduled and executed")
		else
			error("[DescheduleReschedule] Task not executed after rescheduling")
		end
	end, {}, true),

	-- Schedule a task to run immediately
	AddTestWithControl("ScheduleImmediateTask", function(TaskScheduler)
		TaskScheduler:ScheduleTask({
			TaskName = "ScheduleImmediateTask",
			UseSilentOutput = false,
			TaskExecutionDelay = 0,
			TaskAction = function()
				print("[ScheduleImmediateTask] Task ran immediately")
			end
		})
	end, {}, true),

	-- Schedule a task with a negative delay and verify it runs immediately
	AddTestWithControl("ScheduleNegativeDelayTask", function(TaskScheduler)
		TaskScheduler:ScheduleTask({
			TaskName = "ScheduleNegativeDelayTask",
			UseSilentOutput = false,
			TaskExecutionDelay = -1,
			TaskAction = function()
				print("[ScheduleNegativeDelayTask] Task ran immediately")
			end
		})
	end, {}, true),

	-- Schedule a task to run in 1 second and verify it runs after the specified delay
	AddTestWithControl("ScheduleShortDelayedTask", function(TaskScheduler)
		local Delay = 2
		local StartTime = tick()

		TaskScheduler:ScheduleTask({
			TaskName = "ScheduleShortDelayedTask",
			UseSilentOutput = false,
			TaskExecutionDelay = Delay,
			TaskAction = function()
				local EndTime = tick()
				local TimeTaken = EndTime - StartTime

				local ErrorMargin = math.abs((Delay - TimeTaken) / Delay)

				if ErrorMargin < ErrorMarginUpperLimit then -- 15% error margin
					print("[ScheduleShortDelayedTask] Task ran after the specified delay, ErrorMargin: " .. tostring(math.round(ErrorMargin * 100)) .. "%")
				else
					error("[ScheduleShortDelayedTask] Task did not run after the specified delay, ErrorMargin: " .. tostring(math.round(ErrorMargin * 100)) .. "%")
				end
			end
		})
	end, {}, true),

	-- Schedule a task to run after a 5 second delay and verify it runs after the specified delay
	AddTestWithControl("ScheduleMediumDelayedTask", function(TaskScheduler)
		local Delay = 5
		local StartTime = tick()

		TaskScheduler:ScheduleTask({
			TaskName = "ScheduleMediumDelayedTask",
			UseSilentOutput = false,
			TaskExecutionDelay = Delay,
			TaskAction = function()
				local EndTime = tick()
				local TimeTaken = EndTime - StartTime

				local ErrorMargin = math.abs((Delay - TimeTaken) / Delay)

				if ErrorMargin < ErrorMarginUpperLimit then -- 15% error margin
					print("[ScheduleMediumDelayedTask] Task ran after the specified delay, ErrorMargin: " .. tostring(math.round(ErrorMargin * 100)) .. "%")
				else
					error("[ScheduleMediumDelayedTask] Task did not run after the specified delay, ErrorMargin: " .. tostring(math.round(ErrorMargin * 100)) .. "%")
				end
			end
		})
	end, {}, true),

	-- Schedule a task with a long delay and verify it runs after the specified delay
	AddTestWithControl("ScheduleLongDelayedTask", function(TaskScheduler)
		local Delay = 10
		local StartTime = tick()

		TaskScheduler:ScheduleTask({
			TaskName = "ScheduleLongDelayedTask",
			UseSilentOutput = false,
			TaskExecutionDelay = Delay,
			TaskAction = function()
				local EndTime = tick()
				local TimeTaken = EndTime - StartTime

				local ErrorMargin = math.abs((Delay - TimeTaken) / Delay)

				if ErrorMargin < ErrorMarginUpperLimit then -- 15% error margin
					print("[ScheduleLongDelayedTask] Task ran after the specified delay, ErrorMargin: " .. tostring(math.round(ErrorMargin * 100)) .. "%")
				else
					error("[ScheduleLongDelayedTask] Task did not run after the specified delay, ErrorMargin: " .. tostring(math.round(ErrorMargin * 100)) .. "%")
				end
			end
		})
	end, {}, true),

	-- Schedule multiple tasks and verify they run in the correct order
	AddTestWithControl("ScheduleMultipleTasks", function(TaskScheduler)
		local TaskOrder = {}

		TaskScheduler:ScheduleTask({
			TaskName = TaskScheduler:GenerateKey(),
			UseSilentOutput = true,
			TaskExecutionDelay = 1,
			TaskAction = function()
				table.insert(TaskOrder, "Task 1")
			end
		})

		TaskScheduler:ScheduleTask({
			TaskName = TaskScheduler:GenerateKey(),
			UseSilentOutput = true,
			TaskExecutionDelay = 2,
			TaskAction = function()
				table.insert(TaskOrder, "Task 2")
			end
		})

		TaskScheduler:ScheduleTask({
			TaskName = TaskScheduler:GenerateKey(),
			UseSilentOutput = true,
			TaskExecutionDelay = 3,
			TaskAction = function()
				table.insert(TaskOrder, "Task 3")
			end
		})

		TaskScheduler:ScheduleTask({
			TaskName = TaskScheduler:GenerateKey(),
			UseSilentOutput = true,
			TaskExecutionDelay = 4,
			TaskAction = function()
				table.insert(TaskOrder, "Task 4")
			end
		})

		TaskScheduler:ScheduleTask({
			TaskName = TaskScheduler:GenerateKey(),
			UseSilentOutput = true,
			TaskExecutionDelay = 5,
			TaskAction = function()
				table.insert(TaskOrder, "Task 5")

				-- Verify the tasks ran in the correct order
				if TaskOrder[1] == "Task 1" and TaskOrder[2] == "Task 2" and TaskOrder[3] == "Task 3" and TaskOrder[4] == "Task 4" and TaskOrder[5] == "Task 5" then
					print("[ScheduleMultipleTasks] Tasks ran in the correct order")
				else
					error("[ScheduleMultipleTasks] Tasks did not run in the correct order")
				end
			end
		})
	end, {}, true),

	-- Schedule a task with a large number of tasks and verify they all run successfully
	AddTestWithControl("ScheduleManyTasks", function(TaskScheduler)
		local TaskCount = 0
		local MaxTasks = 10000

		for i = 1, MaxTasks do
			TaskScheduler:ScheduleTask({
				TaskName = "Task " .. i,
				UseSilentOutput = true,
				TaskExecutionDelay = 0,
				TaskAction = function()
					TaskCount = TaskCount + 1
				end
			})
		end

		task.wait(3)

		if TaskCount == MaxTasks then
			print("[ScheduleManyTasks] All tasks ran successfully")
		else
			error("[ScheduleManyTasks] Not all tasks ran successfully")
		end
	end, {}, false),

	-- Create a runaway test task and verify it is killed
	AddTestWithControl("RunawayTask", function(TaskScheduler)
		local RunawayTaskCount = 0

		local TaskId = TaskScheduler:ScheduleTask({
			TaskName = "RunawayTask",
			UseSilentOutput = false,
			TaskExecutionDelay = 0,
			IsRecurringTask = true,
			TaskAction = function()
				error("[RunawayTask] Task should have been killed", 0)
			end
		})

		task.wait(3)

		if TaskScheduler.PerformanceManager.TrackedErrorList["RunawayTask"] and TaskScheduler.PerformanceManager.TrackedErrorList["RunawayTask"].n > 0 then
			RunawayTaskCount = TaskScheduler.PerformanceManager.TrackedErrorList["RunawayTask"].n
		else
			error("[RunawayTask] Task did not hit runaway", 0)
		end

		if TaskScheduler["RunawayTask"] then
			error("[RunawayTask] Task was not successfully killed", 0)
		else
			print("[RunawayTask] Task was successfully killed after runaway hit ", RunawayTaskCount)
		end
	end, {}, false),

	-- Test ThrottleThreadCreation setting by scheduling tasks to exceed the ThreadCreationThreshold
	AddTestWithControl("ThrottleThreadCreationSetting", function(TaskScheduler)
		for i = 1, TaskScheduler.Settings.ThreadCreationThreshold + 100 do
			TaskScheduler:ScheduleTask({
				TaskName = "Task" .. i,
				UseSilentOutput = true,
				TaskExecutionDelay = 0,
				TaskAction = function() end
			})
		end

		task.wait(2)
	end, {}, false),

	-- Schedule a task to run every 5 seconds and verify it runs multiple times
	AddTestWithControl("ScheduleRecurringTask", function(TaskScheduler)
		local TaskCount = 0
		local TaskId = TaskScheduler:ScheduleTask({
			TaskName = "ScheduleRecurringTask",
			UseSilentOutput = false,
			TaskExecutionDelay = 1,
			IsRecurringTask = true,
			TaskAction = function()
				TaskCount = TaskCount + 1

				if TaskCount == 3 then
					TaskScheduler:Deschedule("ScheduleRecurringTask")
					print("[ScheduleRecurringTask] Task ran 3 times and was descheduled")
				end
			end
		})

		task.wait(5)

		if TaskScheduler["ScheduleRecurringTask"] or TaskCount ~= 3 then
			error("[ScheduleRecurringTask] Task was not successfully descheduled", 0)
		end
	end, {}, true),

	-- Test a task that runs for a minute
	AddTestWithControl("LongRunningTask", function(TaskScheduler)
		local TaskId = TaskScheduler:ScheduleTask({
			TaskName = "LongRunningTask",
			UseSilentOutput = false,
			IsRecurringTask = true,
			TaskExecutionDelay = 0,
			TaskAction = function()
				task.wait(20)
			end
		})

		local LogResult = FindLogResult(TaskScheduler.Logger, "Long Thread Runtime")

		if LogResult then
			print("[LongRunningTask] Task overran safe thread execution time")
			TaskScheduler:Deschedule("LongRunningTask")
		else
			error("[LongRunningTask] Task did not run for a minute")
		end
	end, {}, true),

	-- Test edge cases
	AddTestWithControl("InvalidInputTest", function(TaskScheduler)
		local success, error = pcall(function()
			TaskScheduler:ScheduleTask({
				UseSilentOutput = false,
				TaskExecutionDelay = "invalid",
				TaskAction = function()
					error("Invalid input test")
				end
			})
		end)

		if not success then
			print("[InvalidInputTest] Invalid input test passed")
		else
			error("[InvalidInputTest] Invalid input test failed")
		end
	end, {}, true),
}

RunTestSuite(testingSuite);