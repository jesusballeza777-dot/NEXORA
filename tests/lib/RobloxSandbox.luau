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
	local env = {
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
	-- con el entorno de motor. Sus dependencias puras se cargan con el arnés normal.
	local function load(path: string): any
		local node: any = VirtualGame.game
		for part in string.gmatch(path, "[^%.]+") do
			node = node:WaitForChild(part)
		end
		return VirtualGame.loadFile(rawget(node, "_file"), node, env)
	end
	return {
		workspace = workspace,
		lighting = lighting,
		terrain = terrain,
		terrainCalls = terrainCalls,
		load = load,
	}
end

return RobloxSandbox
