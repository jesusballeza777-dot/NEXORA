--!strict
-- Coherencia del contrato de red sin ejecutar Roblox: cada acción declarada tiene un
-- manejador registrado en el servidor y cada manejador está declarado. También que el
-- cliente solo pide acciones existentes y escucha mensajes que el servidor envía.

local fs = require("@lune/fs")
local T = harness.T
local expect = T.expect
local Contract = harness.get("ReplicatedStorage.Shared.Net.Contract")
local Actions = harness.get("ServerScriptService.Server.Domain.Actions")
local ProfileSchema = harness.get("ServerScriptService.Server.Domain.ProfileSchema")

local base = "src/" -- las pruebas se ejecutan desde la raíz del repositorio

local function readAll(dir: string, out: { string })
	for _, entry in ipairs(fs.readDir(dir)) do
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			readAll(path, out)
		elseif string.match(entry, "%.luau$") then
			table.insert(out, fs.readFile(path))
		end
	end
	return out
end

local serverSrc = table.concat(readAll(base .. "ServerScriptService", {}), "\n")
local clientSrc = table.concat(readAll(base .. "StarterPlayer", {}), "\n")

T.describe("Contrato de red", function()
	T.it("cada acción del contrato tiene manejador en el servidor", function()
		for name in pairs(Contract.Actions) do
			if not string.find(serverSrc, 'register("' .. name .. '"', 1, true) then
				error("Sin manejador: " .. name)
			end
		end
	end)

	T.it("el servidor no registra acciones fuera del contrato", function()
		for name in string.gmatch(serverSrc, 'register%("([%w%.]+)"') do
			expect(Contract.Actions[name] ~= nil).toBe(true)
		end
	end)

	T.it("el cliente solo solicita acciones declaradas", function()
		for name in string.gmatch(clientSrc, 'Net%.request%("([%w%.]+)"') do
			if not Contract.Actions[name] then
				error("El cliente pide una acción no declarada: " .. name)
			end
		end
	end)

	T.it("el cliente escucha mensajes que existen en el contrato", function()
		local pushes = {}
		for _, v in pairs(Contract.Push) do
			pushes[v] = true
		end
		for name in string.gmatch(clientSrc, 'Net%.on%("(%w+)"') do
			if not pushes[name] then
				error("Mensaje desconocido: " .. name)
			end
		end
	end)

	T.it("las acciones de desarrollador están marcadas devOnly", function()
		for name, spec in pairs(Contract.Actions) do
			if string.sub(name, 1, 4) == "Dev." then
				expect(spec.devOnly).toBe(true)
			end
		end
	end)
end)

T.describe("Onboarding tolerante al orden", function()
	T.it("alimentar antes de colocar no rompe el tutorial", function()
		local now = 1_800_000_000
		local ctx = { now = now }
		local p = ProfileSchema.new(5, now)
		Actions.onLoad(p, ctx)
		Actions.finishIntro(p, true, ctx)
		local petId = Actions.chooseStarter(p, "EggBrasa", ctx).data.petId
		Actions.ackHatch(p, ctx)
		Actions.visitHome(p, ctx)
		-- El jugador alimenta y juega antes de colocar en el hábitat
		Actions.feed(p, petId, "RacionBasica", ctx)
		Actions.play(p, petId, ctx)
		expect(p.onboarding.step).toBe("PlaceInHabitat")
		Actions.place(p, petId, 2, ctx)
		-- Al colocar, los pasos ya cumplidos se completan de golpe
		expect(p.onboarding.step).toBe("FirstBattle")
	end)

	T.it("al recargar a mitad de la eclosión no se queda atascado", function()
		local now = 1_800_000_000
		local ctx = { now = now }
		local p = ProfileSchema.new(6, now)
		Actions.onLoad(p, ctx)
		Actions.finishIntro(p, false, ctx)
		Actions.chooseStarter(p, "EggGreca", ctx)
		expect(p.onboarding.step).toBe("Hatch")
		Actions.onLoad(p, ctx) -- reconexión
		expect(p.onboarding.step).toBe("MeetHome")
	end)
end)
