-- Brainrot Bay shared tuning.
-- One table for every number the map and the timers share, so the server, the
-- client and the screenshots never disagree about where anything stands.
-- The base positions and colours here match the BaseFloor parts in
-- default.project.json exactly.

local Config = {}

-- The belt: brainrots walk it from the green gate in the west to the red
-- gate in the east, along the north edge of the map.
Config.CONVEYOR = {
	Z = -40,
	StartX = -58,
	EndX = 58,
	BeltTopY = 1,
	Speed = 4, -- studs per second along the belt
	SpawnInterval = 5, -- seconds between new brainrots
	MaxOnBelt = 8,
}

-- The eight player bases. Two rows of four: the north row sits just below
-- the shop, the south row along the bottom of the map.
local function base(index: number, x: number, z: number, r: number, g: number, b: number)
	return { Index = index, Center = Vector3.new(x, 1, z), Color = Color3.fromRGB(r, g, b) }
end

Config.BASES = {
	base(1, -45, 12, 217, 64, 64),
	base(2, -15, 12, 242, 140, 38),
	base(3, 15, 12, 242, 217, 51),
	base(4, 45, 12, 64, 191, 77),
	base(5, -45, 42, 51, 128, 242),
	base(6, -15, 42, 153, 77, 217),
	base(7, 15, 42, 242, 115, 179),
	base(8, 45, 42, 51, 204, 217),
}

Config.BASE_FLOOR_SIZE = Vector3.new(20, 1, 24)

-- Slot pads: six open from the start, in two rows of three, and six more
-- (one row at each end) when the Base Extension upgrade is bought. The pads
-- themselves are built at runtime by WorldBuilder; these offsets place them.
Config.SLOTS_PER_BASE = 6
Config.MAX_SLOTS = 12
Config.SLOT_SIZE = Vector3.new(4, 0.3, 4)
Config.SLOT_OFFSETS = {
	Vector3.new(-6, 0, -6),
	Vector3.new(0, 0, -6),
	Vector3.new(6, 0, -6),
	Vector3.new(-6, 0, 6),
	Vector3.new(0, 0, 6),
	Vector3.new(6, 0, 6),
	Vector3.new(-6, 0, -10),
	Vector3.new(0, 0, -10),
	Vector3.new(6, 0, -10),
	Vector3.new(-6, 0, 10),
	Vector3.new(0, 0, 10),
	Vector3.new(6, 0, 10),
}

function Config.slotCenter(baseIndex: number, slotIndex: number): Vector3
	local found = Config.BASES[baseIndex]
	local off = Config.SLOT_OFFSETS[slotIndex]
	return Vector3.new(found.Center.X + off.X, 1.3, found.Center.Z + off.Z)
end

-- Is this point standing on the given base's floor? The wave uses it: a
-- player on their own base is safe from the tsunami.
function Config.isOnBase(point: Vector3, baseIndex: number): boolean
	local found = Config.BASES[baseIndex]
	local half = Config.BASE_FLOOR_SIZE / 2
	return math.abs(point.X - found.Center.X) <= half.X
		and math.abs(point.Z - found.Center.Z) <= half.Z
end

-- The shop kiosk in the middle of the map.
Config.SHOP = {
	Center = Vector3.new(0, 1, -12),
	Radius = 8,
}

-- The tsunami: a warning, then a wall of water sweeping north to south.
Config.WAVE = {
	CycleSeconds = 180, -- a wave every 3 minutes
	WarnSeconds = 10, -- warning before the wall arrives
	SweepSeconds = 8, -- how long the wall takes to cross the map
	StunSeconds = 3, -- how long a caught player is knocked down
	DropCarried = true, -- a caught player drops what they carry
}

-- Golden Hour: a random event that doubles income and boosts golden spawns.
Config.GOLDEN_HOUR = {
	ChancePerMinute = 0.2, -- rolled once a minute while no event runs
	DurationSeconds = 60,
	IncomeMultiplier = 2,
}

Config.START_CASH = 100
Config.INCOME_TICK_SECONDS = 1
Config.BASE_WALK_SPEED = 16
Config.CARRY_WALK_SPEED = 11 -- slower while hauling a stolen brainrot
Config.SLAP_COOLDOWN_SECONDS = 3
Config.LOCK_SECONDS = 45 -- how long a base lock lasts
Config.LOCK_COOLDOWN_SECONDS = 120
Config.STEAL_RANGE = 8 -- studs: how close you must be to grab a brainrot
Config.BUY_RANGE = 10 -- studs: how close you must be to buy off the belt

return Config
