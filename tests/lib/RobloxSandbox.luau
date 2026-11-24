--!strict
-- Ejecuta módulos de Roblox que usan el motor (Instance, CFrame, Enum…) dentro de Lune,
-- con las clases reales de @lune/roblox: asignar una propiedad o clase inexistente
-- falla igual que en Studio. Así se prueban ValleBuilder y CreatureBuilder sin Studio.
-- Terrain no tiene geometría en Lune: sus métodos de relleno se registran en
-- `terrainCalls` (los usa la vista del mundo).
-- No sustituye a Studio: no hay física, render, red ni ciclo de juego.

local roblox = require("@lune/roblox")
local VirtualGame = require("./VirtualGame")

local terrainCalls: { { method: string, args: { any } } } = {}
for _, method in ipairs({ "FillBlock", "FillBall", "FillCylinder", "FillWedge", "SetMaterialColor" }) do
	roblox.implementMethod("Terrain", method, function(_self, ...)
		table.insert(terrainCalls, { method = method, args = { ... } })
	end)
end

local RobloxSandbox = {}
RobloxSandbox.roblox = roblox

export type Sandbox = {
	workspace: any,
	lighting: any,
	terrain: any,
	terrainCalls: { { method: string, args: { any } } },
	load: (path: string) -> any,
}

function RobloxSandbox.new(): Sandbox
	table.clear(terrainCalls)
	local dm = roblox.Instance.new("DataModel")
	local workspace = dm:GetService("Workspace")
	local lighting = dm:GetService("Lighting")
	local terrain = roblox.Instance.new("Terrain")
	terrain.Parent = workspace
	local fakeGame = {
		GetService = function(_, name: string)
			if name == "Workspace" then
				return workspace
			elseif name == "Lighting" then
				return lighting
			end
			return VirtualGame.game:GetService(name)
		end,
	}
	local env: { [string]: any } = {
		game = fakeGame,
		workspace = workspace,
		Instance = roblox.Instance,
		Vector2 = roblox.Vector2,
		Vector3 = roblox.Vector3,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
		Enum = roblox.Enum,
	}
	-- Carga un ModuleScript del árbol de Rojo ("ServerScriptService.Server.World.ValleBuilder")
	-- con el entorno de motor. Sus dependencias de servidor y cliente también lo reciben
	-- (caché por sandbox); las de ReplicatedStorage (puras) se cargan con el arnés normal.
	local cache: { [any]: any } = {}
	local function sandboxRequire(target: any): any
		if type(target) == "string" then
			return require(target)
		end
		local path = target:GetFullName()
		if
			not string.find(path, "ServerScriptService", 1, true)
			and not string.find(path, "StarterPlayerScripts", 1, true)
		then
			return VirtualGame.require(target)
		end
		if cache[target] == nil then
			cache[target] = VirtualGame.loadFile(rawget(target, "_file"), target, env)
		end
		return cache[target]
	end
	env.require = sandboxRequire
	local function load(path: string): any
		local node: any = VirtualGame.game
		for part in string.gmatch(path, "[^%.]+") do
			node = node:WaitForChild(part)
		end
		return sandboxRequire(node)
	end
	return {
		workspace = workspace,
		lighting = lighting,
		terrain = terrain,
		terrainCalls = terrainCalls,
		load = load,
	}
end

-- ======================================================================
-- Cliente: carga módulos de StarterPlayerScripts con clases reales de Roblox, servicios
-- simulados (Players, TweenService, RunService…) y sustitutos para módulos concretos
-- (p. ej. Net y State). Sirve para montar pantallas sin Studio y detectar propiedades
-- mal escritas o accesos a nil. No hay render, input ni red.
-- ======================================================================
local fakeSignal = {
	Connect = function()
		return {
			Disconnect = function() end,
		}
	end,
	Wait = function() end,
}
for _, class in ipairs({ "TextButton", "ImageButton" }) do
	roblox.implementProperty(class, "Activated", function()
		return fakeSignal
	end, function() end)
end
for _, class in ipairs({ "Frame", "ScrollingFrame", "TextButton", "TextLabel", "ViewportFrame", "ImageButton" }) do
	roblox.implementProperty(class, "AbsolutePosition", function()
		return roblox.Vector2.new(0, 0)
	end, function() end)
	roblox.implementProperty(class, "AbsoluteSize", function()
		return roblox.Vector2.new(400, 600)
	end, function() end)
end
roblox.implementMethod("Model", "GetExtentsSize", function(model: any)
	local minV, maxV = nil, nil
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local p, s = d.CFrame.Position, d.Size / 2
			local lo, hi = p - s, p + s
			minV = if minV
				then roblox.Vector3.new(math.min(minV.X, lo.X), math.min(minV.Y, lo.Y), math.min(minV.Z, lo.Z))
				else lo
			maxV = if maxV
				then roblox.Vector3.new(math.max(maxV.X, hi.X), math.max(maxV.Y, hi.Y), math.max(maxV.Z, hi.Z))
				else hi
		end
	end
	return if minV and maxV then maxV - minV else roblox.Vector3.new(1, 1, 1)
end)

export type ClientSandbox = { load: (path: string) -> any, playerGui: any, opened: { string } }

function RobloxSandbox.newClient(stubs: { [string]: any }): ClientSandbox
	local dm = roblox.Instance.new("DataModel")
	local workspace = dm:GetService("Workspace")
	local lighting = dm:GetService("Lighting")
	local playerGui = roblox.Instance.new("Folder")
	playerGui.Name = "PlayerGui"
	local localPlayer = {
		Name = "Tester",
		UserId = 1,
		WaitForChild = function(_, name: string)
			assert(name == "PlayerGui", "LocalPlayer:WaitForChild(" .. name .. ")")
			return playerGui
		end,
		GetAttribute = function()
			return nil
		end,
	}
	-- Workspace sin cámara: la interfaz usa su escala por defecto (900 px de alto)
	local workspaceProxy = setmetatable({}, {
		__index = function(_, key)
			if key == "CurrentCamera" then
				return nil
			end
			return workspace[key]
		end,
	})
	local services = {
		Workspace = workspaceProxy,
		Lighting = lighting,
		Players = { LocalPlayer = localPlayer },
		TweenService = {
			Create = function()
				return { Play = function() end, Cancel = function() end }
			end,
		},
		RunService = {
			Heartbeat = fakeSignal,
			RenderStepped = fakeSignal,
			IsStudio = function()
				return true
			end,
		},
		HttpService = {
			JSONEncode = function(_, v)
				return require("@lune/serde").encode("json", v)
			end,
			JSONDecode = function(_, v)
				return require("@lune/serde").decode("json", v)
			end,
		},
	}
	local fakeGame = {
		GetService = function(_, name: string)
			return services[name] or VirtualGame.game:GetService(name)
		end,
	}
	local cache: { [any]: any } = {}
	local env: { [string]: any } = {}
	local function clientRequire(target: any): any
		if type(target) == "string" then
			return require(target)
		end
		local path = target:GetFullName()
		for suffix, stub in pairs(stubs) do
			if string.sub(path, -#suffix) == suffix then
				return stub
			end
		end
		if not string.find(path, "StarterPlayerScripts", 1, true) then
			return VirtualGame.require(target)
		end
		if cache[target] == nil then
			cache[target] = VirtualGame.loadFile(rawget(target, "_file"), target, env)
		end
		return cache[target]
	end
	for k, v in pairs({
		game = fakeGame,
		workspace = workspace,
		require = clientRequire,
		Instance = roblox.Instance,
		Vector2 = roblox.Vector2,
		Vector3 = roblox.Vector3,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
		Enum = roblox.Enum,
		TweenInfo = {
			new = function()
				return {}
			end,
		},
		task = {
			spawn = function() end,
			wait = function()
				return 0
			end,
			delay = function() end,
		},
	}) do
		env[k] = v
	end
	local function load(path: string): any
		local node: any = VirtualGame.game
		for part in string.gmatch(path, "[^%.]+") do
			node = node:WaitForChild(part)
		end
		return clientRequire(node)
	end
	return { load = load, playerGui = playerGui, opened = {} }
end

return RobloxSandbox
