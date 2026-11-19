-- EventService: Golden Hour, the random event that shakes up the economy.
-- About once every five minutes the bay goes gold for a minute: every
-- brainrot earns double, and the next spawns roll luckier. The whole server
-- hears about it at once, so everyone rushes the belt together.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local EventService = {}

function EventService.start()
	task.spawn(function()
		while true do
			task.wait(60)
			if not PlayerState.isGoldenHour() and math.random() < Config.GOLDEN_HOUR.ChancePerMinute then
				PlayerState.setGoldenHour(true)
				PlayerState.announce(
					"GOLDEN HOUR! All income x2 for " .. tostring(Config.GOLDEN_HOUR.DurationSeconds) .. " seconds!",
					"Gold",
					6
				)
				task.wait(Config.GOLDEN_HOUR.DurationSeconds)
				PlayerState.setGoldenHour(false)
				PlayerState.announce("Golden Hour is over. Back to normal rates.", "White", 4)
			end
		end
	end)
end

return EventService
