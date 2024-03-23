repeat task.wait() until shared.TaskManager;

local TaskManagerModule = require(script.TaskManager);
local TaskScheduler = shared.TaskManager

-- Initialize the task manager
local TaskManager = TaskManagerModule:Initialize();

while task.wait() do
    TaskManager:Update();
end;