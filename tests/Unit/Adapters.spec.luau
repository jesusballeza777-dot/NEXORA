--!strict
-- Lógica pura extraída de los adaptadores de Roblox (revisión del vertical slice):
-- reparto de mensajes push, campos de analítica, registro de rechazos y DevGate.
local T = harness.T
local expect = T.expect
local game = harness.game
local PushBuffer = harness.get("StarterPlayerScripts.Client.PushBuffer")
local AnalyticsFields = harness.get("ServerScriptService.Server.Util.AnalyticsFields")
local Guard = harness.get("ServerScriptService.Server.Util.Guard")

local function syncSpawn(fn: (any) -> (), payload: any)
	fn(payload)
end

T.describe("PushBuffer: mensajes antes de tener oyente", function()
	T.it("entrega el perfil que llegó antes de conectar el oyente (bug: primer perfil perdido)", function()
		local buffer = PushBuffer.new({ latestOnly = { "Profile" }, maxPending = 4, spawn = syncSpawn })
		buffer.push("Profile", { v = 1 })
		local got = {}
		buffer.on("Profile", function(view)
			table.insert(got, view.v)
		end)
		expect(#got).toBe(1)
		expect(got[1]).toBe(1)
	end)
	T.it("de la vista del perfil solo se conserva la más reciente", function()
		local buffer = PushBuffer.new({ latestOnly = { "Profile" }, maxPending = 4, spawn = syncSpawn })
		buffer.push("Profile", { v = 1 })
		buffer.push("Profile", { v = 2 })
		local got = {}
		buffer.on("Profile", function(view)
			table.insert(got, view.v)
		end)
		expect(#got).toBe(1)
		expect(got[1]).toBe(2)
	end)
	T.it("el resto de mensajes se conserva en orden y con límite", function()
		local buffer = PushBuffer.new({ latestOnly = {}, maxPending = 3, spawn = syncSpawn })
		for i = 1, 5 do
			buffer.push("Toast", i)
		end
		local got = {}
		buffer.on("Toast", function(n)
			table.insert(got, n)
		end)
		expect(got).toEqual({ 1, 2, 3 })
	end)
	T.it("con oyente conectado entrega en directo y no repite lo ya entregado", function()
		local buffer = PushBuffer.new({ latestOnly = { "Profile" }, maxPending = 4, spawn = syncSpawn })
		local a, b = 0, 0
		buffer.on("Profile", function()
			a += 1
		end)
		buffer.push("Profile", {})
		buffer.on("Profile", function()
			b += 1
		end)
		buffer.push("Profile", {})
		expect(a).toBe(2)
		expect(b).toBe(1)
	end)
end)

T.describe("Campos de analítica (AnalyticsService)", function()
	local KEYS = { "CustomField01", "CustomField02", "CustomField03" }
	T.it("usa las claves fijas en orden alfabético de campo y formato 'clave - valor'", function()
		local custom, value = AnalyticsFields.encode({ won = true, encounter = "valle_r1_e1", reason = "KO" }, KEYS)
		expect(custom).toEqual({
			CustomField01 = "encounter - valle_r1_e1",
			CustomField02 = "reason - KO",
			CustomField03 = "won - true",
		})
		expect(value).toBe(1)
	end)
	T.it("los números van al valor del evento, no a los campos", function()
		local custom, value = AnalyticsFields.encode({ amount = 120 }, KEYS)
		expect(custom).toBe(nil)
		expect(value).toBe(120)
		local c2, v2 = AnalyticsFields.encode({ encounter = "e", turns = 7, won = false, reason = "KO" }, KEYS)
		expect(v2).toBe(7)
		expect((c2 :: any).CustomField03).toBe("won - false")
	end)
	T.it("nunca pasa de 3 campos ni de la longitud máxima", function()
		local custom = AnalyticsFields.encode({ a = "1", b = "2", c = "3", d = "4", e = string.rep("x", 200) }, KEYS)
		local n = 0
		for _, v in pairs(custom :: any) do
			n += 1
			expect(#v <= AnalyticsFields.MAX_TEXT).toBe(true)
		end
		expect(n).toBe(3)
	end)
end)

T.describe("Registro de rechazos remotos", function()
	T.it("limita los registros por ventana y se reinicia al pasar la ventana", function()
		local w = Guard.newWindow(0)
		local allowed = 0
		for _ = 1, 50 do
			if Guard.allowInWindow(w, 5, 60, 10) then
				allowed += 1
			end
		end
		expect(allowed).toBe(5)
		expect(Guard.allowInWindow(w, 5, 60, 70)).toBe(true)
	end)
end)

T.describe("DevGate: comandos de prueba solo en Studio", function()
	local node = game.ServerScriptService.Server.Services.DevGate
	local function load(isStudio: boolean)
		local fakeGame = {
			GetService = function(_, name: string)
				if name == "RunService" then
					return {
						IsStudio = function()
							return isStudio
						end,
					}
				end
				return game:GetService(name)
			end,
		}
		return harness.loadFile(rawget(node, "_file"), node, { game = fakeGame })
	end
	local fakePlayer = {
		UserId = 42,
		GetAttribute = function(_, name: string)
			return name == "NexoDevBoost"
		end,
	}
	T.it("en un servidor publicado nunca hay multiplicadores", function()
		local gate = load(false)
		expect(gate.isDev(fakePlayer)).toBe(false)
		local ctx = gate.ctxFor(fakePlayer, 100)
		expect(ctx.xpMultiplier).toBe(nil)
		expect(ctx.coinMultiplier).toBe(nil)
	end)
	T.it("en Studio se activan con el atributo NexoDevBoost", function()
		local gate = load(true)
		expect(gate.isDev(fakePlayer)).toBe(true)
		expect(gate.ctxFor(fakePlayer, 100).xpMultiplier ~= nil).toBe(true)
	end)
end)
