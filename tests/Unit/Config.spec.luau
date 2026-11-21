--!strict
-- Valida la configuración contra las reglas de la Biblia v5.0. Si alguien
-- transcribe mal un número, estas pruebas lo detectan.

local T = harness.T
local expect = T.expect
local Species = harness.get("ReplicatedStorage.Shared.Config.Species")
local Rarities = harness.get("ReplicatedStorage.Shared.Config.Rarities")
local Elements = harness.get("ReplicatedStorage.Shared.Config.Elements")
local Abilities = harness.get("ReplicatedStorage.Shared.Config.Abilities")
local Talents = harness.get("ReplicatedStorage.Shared.Config.Talents")
local Visuals = harness.get("ReplicatedStorage.Shared.Config.Visuals")
local Encounters = harness.get("ReplicatedStorage.Shared.Config.Encounters")
local Rewards = harness.get("ReplicatedStorage.Shared.Config.Rewards")
local Economy = harness.get("ReplicatedStorage.Shared.Config.Economy")
local Onboarding = harness.get("ReplicatedStorage.Shared.Config.Onboarding")
local Roles = harness.get("ReplicatedStorage.Shared.Config.Roles")

T.describe("Catálogo de especies (p. 52–53)", function()
	T.it("tiene 50 especies numeradas 1..50 sin huecos", function()
		expect(#Species.Order).toBe(50)
		local seen = {}
		for _, id in ipairs(Species.Order) do
			local s = Species.ById[id]
			expect(seen[s.number]).toBe(nil)
			seen[s.number] = true
		end
		for n = 1, 50 do
			expect(seen[n]).toBe(true)
		end
	end)

	T.it("cada especie reparte exactamente el presupuesto de su rareza", function()
		for _, id in ipairs(Species.Order) do
			local s = Species.ById[id]
			local sum = s.stats.VID + s.stats.ATQ + s.stats.DEF + s.stats.ESE + s.stats.VEL
			local budget = Rarities.ById[s.rarity].statBudget
			if sum ~= budget then
				error(string.format("%s suma %d, presupuesto %d", s.talladoName, sum, budget))
			end
		end
	end)

	T.it("respeta el reparto de rarezas 18 · 14 · 10 · 5 · 2 · 1", function()
		local counts = {}
		for _, id in ipairs(Species.Order) do
			local r = Species.ById[id].rarity
			counts[r] = (counts[r] or 0) + 1
		end
		for _, r in ipairs(Rarities.Order) do
			expect(counts[r]).toBe(Rarities.ById[r].catalogCount)
		end
	end)

	T.it("cuenta de especies por elemento coincide con la p. 31", function()
		local counts = {}
		for _, id in ipairs(Species.Order) do
			for _, e in ipairs(Species.ById[id].elements) do
				counts[e] = (counts[e] or 0) + 1
			end
		end
		for _, e in ipairs(Elements.Order) do
			if counts[e] ~= Elements.ById[e].speciesCount then
				error(
					string.format(
						"%s: %s especies, la Biblia dice %d",
						e,
						tostring(counts[e]),
						Elements.ById[e].speciesCount
					)
				)
			end
		end
	end)

	T.it("reparto por bioma 14 · 8 · 8 · 7 · 12 · 1 (p. 10)", function()
		local counts = {}
		for _, id in ipairs(Species.Order) do
			local b = Species.ById[id].biome
			counts[b] = (counts[b] or 0) + 1
		end
		expect(counts.ValleCopal).toBe(14)
		expect(counts.CumbreBrasa).toBe(8)
		expect(counts.MareaCoralina).toBe(8)
		expect(counts.MesetaFulgor).toBe(7)
		expect(counts.VeloAstral).toBe(12)
		expect(counts.TorreDelNexo).toBe(1)
	end)

	T.it("los iniciales conservan elemento y rol de la Biblia", function()
		expect(Species.ById.kuachi.elements[1]).toBe("Fuego")
		expect(Species.ById.kuachi.role).toBe("Atacante")
		expect(Species.ById.kuachi.talladoName).toBe("Ascuacho")
		expect(Species.ById.xolumi.elements[1]).toBe("Agua")
		expect(Species.ById.xolumi.role).toBe("Soporte")
		expect(Species.ById.xolumi.talladoName).toBe("Xolossus")
		expect(Species.ById.teselo.elements[1]).toBe("Tierra")
		expect(Species.ById.teselo.role).toBe("Defensor")
		expect(Species.ById.teselo.talladoName).toBe("Mitlaxis")
	end)

	T.it("todos los roles usados existen", function()
		for _, id in ipairs(Species.Order) do
			expect(Roles.ById[Species.ById[id].role] ~= nil).toBe(true)
		end
	end)
end)

T.describe("Rueda de elementos (p. 31–32)", function()
	T.it("cada elemento vence exactamente a 2 y pierde contra 2", function()
		for _, id in ipairs(Elements.Order) do
			local e = Elements.ById[id]
			expect(#e.strongAgainst).toBe(2)
			expect(#e.weakAgainst).toBe(2)
		end
	end)

	T.it("las debilidades son el reflejo exacto de las fortalezas", function()
		for _, id in ipairs(Elements.Order) do
			local beatenBy = {}
			for _, other in ipairs(Elements.Order) do
				if table.find(Elements.ById[other].strongAgainst, id) then
					table.insert(beatenBy, other)
				end
			end
			table.sort(beatenBy)
			local declared = table.clone(Elements.ById[id].weakAgainst)
			table.sort(declared)
			expect(beatenBy).toEqual(declared)
		end
	end)

	T.it("ningún par se vence mutuamente", function()
		for _, a in ipairs(Elements.Order) do
			for _, b in ipairs(Elements.ById[a].strongAgainst) do
				expect(table.find(Elements.ById[b].strongAgainst, a)).toBe(nil)
			end
		end
	end)

	T.it("conserva el triángulo Agua → Fuego → Flora → Agua", function()
		expect(table.find(Elements.ById.Agua.strongAgainst, "Fuego") ~= nil).toBe(true)
		expect(table.find(Elements.ById.Fuego.strongAgainst, "Flora") ~= nil).toBe(true)
		expect(table.find(Elements.ById.Flora.strongAgainst, "Agua") ~= nil).toBe(true)
	end)
end)

T.describe("Repertorio (p. 36–38)", function()
	T.it("cada elemento tiene 3 básicos, 2 especiales y 1 Golpe Nexo válidos", function()
		for _, e in ipairs(Elements.Order) do
			local rep = Abilities.ByElement[e]
			expect(#rep.basics).toBe(3)
			expect(#rep.specials).toBe(2)
			for _, id in ipairs(rep.basics) do
				expect(Abilities.ById[id].kind).toBe("Basic")
				expect(Abilities.ById[id].element).toBe(e)
			end
			for _, id in ipairs(rep.specials) do
				expect(Abilities.ById[id].kind).toBe("Special")
			end
			expect(Abilities.ById[rep.nexo].kind).toBe("Nexo")
		end
	end)

	T.it("todos los Golpes Nexo tienen poder 115–130 (p. 43)", function()
		for _, e in ipairs(Elements.Order) do
			local p = Abilities.ById[Abilities.ByElement[e].nexo].power
			expect(p).toBeAtLeast(115)
			expect(p <= 130).toBe(true)
		end
	end)

	T.it("las especies del vertical slice tienen talento, firma y visual", function()
		for _, id in ipairs(Species.Order) do
			local s = Species.ById[id]
			if s.status == "VerticalSlice" then
				expect(Talents.ById[s.talent] ~= nil).toBe(true)
				expect(Abilities.ById[s.signature].kind).toBe("Signature")
				expect(Visuals.ById[id] ~= nil).toBe(true)
				expect(Visuals.ById[id].assetStatus).toBe("Blockout")
			end
		end
	end)
end)

T.describe("Contenido del vertical slice", function()
	T.it("los huevos iniciales apuntan a los tres iniciales", function()
		expect(#Onboarding.StarterEggs).toBe(3)
		for _, egg in ipairs(Onboarding.StarterEggs) do
			expect(table.find(Species.Starters, egg.speciesId) ~= nil).toBe(true)
		end
	end)

	T.it("cada encuentro usa especies jugables y bonos existentes", function()
		for _, id in ipairs(Encounters.Order) do
			local enc = Encounters.ById[id]
			if enc.opponent.speciesId then
				expect(Species.ById[enc.opponent.speciesId].status).toBe("VerticalSlice")
			else
				for element, sp in pairs(enc.opponent.byStarterElement) do
					expect(Species.ById[sp].status).toBe("VerticalSlice")
					-- El primer Opaco es débil ante el inicial correspondiente (p. 48)
					local starterStrong = Elements.ById[element].strongAgainst
					expect(table.find(starterStrong, Species.ById[sp].elements[1]) ~= nil).toBe(true)
				end
			end
			if enc.firstClearBonus then
				expect(Rewards.ById[enc.firstClearBonus] ~= nil).toBe(true)
			end
		end
	end)

	T.it("las recompensas solo usan monedas y objetos existentes", function()
		for id, bundle in pairs(Rewards.ById) do
			expect(bundle.id).toBe(id)
			for cur in pairs(bundle.currencies or {}) do
				expect(Economy.Currencies[cur] ~= nil).toBe(true)
			end
			for item in pairs(bundle.items or {}) do
				expect(Economy.Foods[item] ~= nil).toBe(true)
			end
		end
	end)

	T.it("la configuración está congelada (no se puede mutar en ejecución)", function()
		expect(function()
			(Species.ById.kuachi :: any).rarity = "Unico"
		end).toThrow()
	end)
end)
