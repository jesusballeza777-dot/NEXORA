--!strict
-- Ejecutor de pruebas de NEXORA sobre Lune.
-- Emula el árbol de instancias que Rojo genera desde src/ (default.project.json) para
-- que los módulos usen exactamente los mismos require(script.Parent.X) que en Roblox.
-- Solo pueden probarse aquí los módulos puros (sin APIs de motor). Los servicios que
-- usan DataStoreService, Players, etc. se validan en Roblox Studio (tests/Playtest).
--
-- Uso:  lune run tests/runner            (todas las pruebas)
--       lune run tests/runner Battle     (solo archivos cuyo nombre contenga "Battle")

local fs = require("@lune/fs")
local process = require("@lune/process")
local VirtualGame = require("./lib/VirtualGame")

local ROOT = VirtualGame.ROOT
local game = VirtualGame.game
local harnessRequire = VirtualGame.require
local get = VirtualGame.get
local loadFile = VirtualGame.loadFile
local newNode = VirtualGame.newNode

-- ------------------------------------------------------------------
-- Mini framework de pruebas
-- ------------------------------------------------------------------
local results = { passed = 0, failed = 0, failures = {} :: { string } }
local currentSuite = ""

local function deepEqual(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not deepEqual(v, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

local function fmt(v: any): string
	if type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

local function expect(actual: any)
	local api = {}
	function api.toBe(expected: any)
		if actual ~= expected then
			error(string.format("se esperaba %s, se obtuvo %s", fmt(expected), fmt(actual)), 2)
		end
	end
	function api.toEqual(expected: any)
		if not deepEqual(actual, expected) then
			error("las tablas no son iguales", 2)
		end
	end
	function api.toBeNear(expected: number, eps: number?)
		local e = eps or 1e-6
		if math.abs(actual - expected) > e then
			error(string.format("se esperaba ≈%s (±%s), se obtuvo %s", fmt(expected), fmt(e), fmt(actual)), 2)
		end
	end
	function api.toBeTruthy()
		if not actual then
			error("se esperaba un valor verdadero, se obtuvo " .. fmt(actual), 2)
		end
	end
	function api.toBeFalsy()
		if actual then
			error("se esperaba un valor falso, se obtuvo " .. fmt(actual), 2)
		end
	end
	function api.toBeGreaterThan(n: number)
		if not (actual > n) then
			error(string.format("se esperaba > %s, se obtuvo %s", fmt(n), fmt(actual)), 2)
		end
	end
	function api.toBeLessThan(n: number)
		if not (actual < n) then
			error(string.format("se esperaba < %s, se obtuvo %s", fmt(n), fmt(actual)), 2)
		end
	end
	function api.toBeAtLeast(n: number)
		if not (actual >= n) then
			error(string.format("se esperaba >= %s, se obtuvo %s", fmt(n), fmt(actual)), 2)
		end
	end
	function api.toThrow()
		local ok = pcall(actual)
		if ok then
			error("se esperaba un error", 2)
		end
	end
	function api.toContain(item: any)
		if type(actual) == "string" then
			if not string.find(actual, item, 1, true) then
				error(string.format("%s no contiene %s", fmt(actual), fmt(item)), 2)
			end
			return
		end
		for _, v in ipairs(actual) do
			if v == item then
				return
			end
		end
		error("la lista no contiene " .. fmt(item), 2)
	end
	return api
end

local T = {
	expect = expect,
	describe = function(name: string, fn: () -> ())
		local prev = currentSuite
		currentSuite = if prev == "" then name else prev .. " › " .. name
		fn()
		currentSuite = prev
	end,
	it = function(name: string, fn: () -> ())
		local ok, err = pcall(fn)
		if ok then
			results.passed += 1
		else
			results.failed += 1
			table.insert(results.failures, string.format("✗ %s › %s\n    %s", currentSuite, name, tostring(err)))
		end
	end,
}

-- ------------------------------------------------------------------
-- Descubrimiento y ejecución
-- ------------------------------------------------------------------
local filter: string? = nil
for _, arg in ipairs(process.args) do
	if arg ~= "--" then
		filter = arg
		break
	end
end
local specs = {}
local function collect(dir: string)
	for _, entry in ipairs(fs.readDir(dir)) do
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			collect(path)
		elseif string.match(entry, "%.spec%.luau$") then
			if not filter or string.find(entry, filter, 1, true) then
				table.insert(specs, path)
			end
		end
	end
end
collect(ROOT .. "tests")
table.sort(specs)

local harness = { get = get, T = T, game = game, require = harnessRequire, loadFile = loadFile }
local started = os.clock()
for _, path in ipairs(specs) do
	local rel = string.gsub(path, "^" .. ROOT, "")
	currentSuite = rel
	local ok, err = pcall(loadFile, path, newNode("Spec", "ModuleScript", nil, path), { harness = harness })
	if not ok then
		results.failed += 1
		table.insert(results.failures, string.format("✗ %s (error al cargar)\n    %s", rel, tostring(err)))
	end
end
local elapsed = os.clock() - started

for _, f in ipairs(results.failures) do
	print(f)
end
print(
	string.format(
		"\n%d archivos · %d pruebas OK · %d fallidas · %.2fs",
		#specs,
		results.passed,
		results.failed,
		elapsed
	)
)
if results.failed > 0 then
	process.exit(1)
end
