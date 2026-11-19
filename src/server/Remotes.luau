-- Remotes: the one place that creates every RemoteEvent the game uses.
-- The client never talks to the server except through these, and the server
-- never pushes state except through StateSync and Announce.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local NAMES = {
	"BuyBrainrot", -- client -> server, arg: brainrot uid (number)
	"StealBrainrot", -- client -> server, arg: brainrot uid (number)
	"SlapPlayer", -- client -> server, no args: slap the nearest carrier
	"ToggleLock", -- client -> server, no args: lock your base
	"BuyUpgrade", -- client -> server, arg: "Speed" | "Slots"
	"Rebirth", -- client -> server, no args
	"StateSync", -- server -> client, arg: state table
	"Announce", -- server -> client, args: text, colorName, seconds
}

function Remotes.init()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	for _, name in ipairs(NAMES) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
	end
	return folder
end

function Remotes.get(name: string): RemoteEvent
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name) :: RemoteEvent
end

return Remotes
