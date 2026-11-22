--!strict
-- Prueba de humo de la interfaz de Roblox SIN Studio: monta cada pantalla de la Fase 2
-- con clases reales de @lune/roblox (una propiedad mal escrita falla igual que en Studio)
-- y con vistas de perfil reales construidas por el servidor (ProfileView), pasadas por
-- JSON como llegarían por red. No valida aspecto ni input: eso sigue siendo de Studio.
local T = harness.T
local expect = T.expect
local serde = require("@lune/serde")
local Play = harness.require("./Play")(harness)
local Actions = harness.get("ServerScriptService.Server.Domain.Actions")
local ProfileView = harness.get("ServerScriptService.Server.Domain.ProfileView")
local PetRules = harness.get("ServerScriptService.Server.Domain.PetRules")
local EggRules = harness.get("ServerScriptService.Server.Domain.EggRules")
local ChestRules = harness.get("ServerScriptService.Server.Domain.ChestRules")
local Encounters = harness.get("ReplicatedStorage.Shared.Config.Encounters")

-- Perfil "avanzado": varias especies, huevos, cofres, decoración y etapas superadas
local function lateProfile(): (any, any)
	local p, starter = Play.tutorialProfile(1500, "EggBrasa")
	Play.boost(p, starter, 22, "Tallado")
	local extra = PetRules.create(p, "zunzi", { kind = "Dev", at = Play.now }).data.petId
	Play.boost(p, extra, 22, "Tallado")
	Actions.setTeam(p, { starter, extra }, Play.ctx())
	local r = Play.encounter(p, "valle_r1_e1", "UI1", 5)
	assert(r.ok)
	Play.encounter(p, "valle_r1_e2", "UI2", 6)
	local egg = EggRules.grant(p, "vainas", { kind = "Test", at = Play.now }, Play.now).data.eggId
	EggRules.grant(p, "pabilo", { kind = "Test", at = Play.now }, Play.now)
	Actions.startIncubation(p, egg, 1, Play.ctx())
	ChestRules.grant(p, "Plata", { kind = "Test", at = Play.now }, Play.now)
	ChestRules.grant(p, "Nexo", { kind = "Test", at = Play.now }, Play.now)
	p.decor.owned.FarolDeCopal = 1
	p.decor.slots[1] = "FarolDeCopal"
	p.titles.owned["Guardián del Valle"] = Play.now
	p.codex["opaco:ActoI"] = Play.now
	return p, starter
end

local function asNetwork(view: any): any
	return serde.decode("json", serde.encode("json", view))
end

local function mountAll(view: any, petIds: { string })
	local requests = {}
	local NetStub = {
		request = function(action: string, ...)
			table.insert(requests, action)
			return { ok = false, err = "Offline" }
		end,
		message = function(err: string?)
			return tostring(err)
		end,
		on = function() end,
	}
	local StateStub = {
		view = view,
		pet = function(id: string?)
			for _, pet in ipairs(view.pets) do
				if pet.id == id then
					return pet
				end
			end
			return nil
		end,
		companion = function()
			return nil
		end,
		step = function()
			return view.onboarding.step
		end,
	}
	local sb = harness.sandbox.newClient({ ["Client.Net"] = NetStub, ["Client.State"] = StateStub })
	local Modals = sb.load("StarterPlayerScripts.Client.UI.Modals")
	Modals.init({ toast = function() end })
	local Collection = sb.load("StarterPlayerScripts.Client.UI.Screens.Collection")
	local Breeding = sb.load("StarterPlayerScripts.Client.UI.Screens.Breeding")
	local Adventure = sb.load("StarterPlayerScripts.Client.UI.Screens.Adventure")
	local SanctuaryPlus = sb.load("StarterPlayerScripts.Client.UI.Screens.SanctuaryPlus")
	local QuickMenu = sb.load("StarterPlayerScripts.Client.UI.QuickMenu")

	Collection.album(nil, nil)
	Collection.album("ValleCopal", "Tallado")
	Collection.album("VeloAstral", "Brote")
	for _, sp in ipairs({ "kuachi", "zunzi", "vainas", "lumbrela" }) do
		Collection.bestiary(sp)
	end
	Collection.codex()
	Breeding.incubator()
	Breeding.chests()
	Breeding.quests()
	Breeding.history()
	Adventure.map()
	for _, id in ipairs(Encounters.Order) do
		Adventure.stage(id)
	end
	Adventure.treasure("valle_r1_e4")
	Adventure.team(nil)
	SanctuaryPlus.decor()
	SanctuaryPlus.showcase()
	QuickMenu.open(function() end, function() end)
	for _, r in ipairs(view.pendingRewards) do
		Modals.reward(r.id)
	end
	for _, id in ipairs(petIds) do
		Modals.petSheet(id)
	end
	Modals.close()
	return requests, sb
end

T.describe("Interfaz Roblox · pantallas de la Fase 2 (humo, sin Studio)", function()
	T.it("todas las pantallas se montan con un perfil nuevo", function()
		local p, starter = Play.tutorialProfile(1501, "EggGreca")
		local view = asNetwork(ProfileView.build(p, Play.now))
		local requests = mountAll(view, { starter })
		-- Montar pantallas nunca envía solicitudes por sí solo
		expect(#requests).toBe(0)
	end)
	T.it("todas las pantallas se montan con un perfil avanzado (huevos, cofres, etapas)", function()
		local p, starter = lateProfile()
		local view = asNetwork(ProfileView.build(p, Play.now))
		local pets = {}
		for _, pet in ipairs(view.pets) do
			table.insert(pets, pet.id)
		end
		expect(#view.chests).toBe(2)
		expect(view.incubators[1].eggId ~= nil).toBe(true)
		local requests = mountAll(view, pets)
		expect(#requests).toBe(0)
		local _ = starter
	end)
end)
