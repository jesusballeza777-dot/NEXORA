--!strict
-- Datos de la Fase 2 contra la Biblia y entre sí (huevos, cofres, encargos, Acto I,
-- Códice, decoración, lore y Seres Sagrados).
local T = harness.T
local expect = T.expect
local Incubation = harness.get("ReplicatedStorage.Shared.Config.Incubation")
local Chests = harness.get("ReplicatedStorage.Shared.Config.Chests")
local Quests = harness.get("ReplicatedStorage.Shared.Config.Quests")
local Encounters = harness.get("ReplicatedStorage.Shared.Config.Encounters")
local Codex = harness.get("ReplicatedStorage.Shared.Config.Codex")
local Decor = harness.get("ReplicatedStorage.Shared.Config.Decor")
local Species = harness.get("ReplicatedStorage.Shared.Config.Species")
local SpeciesLore = harness.get("ReplicatedStorage.Shared.Config.SpeciesLore")
local Visuals = harness.get("ReplicatedStorage.Shared.Config.Visuals")
local Guardians = harness.get("ReplicatedStorage.Shared.Config.Guardians")
local Rarities = harness.get("ReplicatedStorage.Shared.Config.Rarities")
local ElementChart = harness.get("ReplicatedStorage.Shared.Domain.ElementChart")
local ChestRules = harness.get("ServerScriptService.Server.Domain.ChestRules")

T.describe("Incubación (Biblia p. 27 y 102)", function()
	T.it("tiempos por rareza: 5 min · 20 min · 2 h · 8 h · 24 h · 72 h", function()
		local t = Incubation.SecondsByRarity
		expect(t.Comun).toBe(300)
		expect(t.Raro).toBe(1200)
		expect(t.Epico).toBe(7200)
		expect(t.Legendario).toBe(28800)
		expect(t.Unico).toBe(86400)
		expect(t.Misterio).toBe(259200)
	end)
	T.it("5 ranuras; precios de la Biblia; sin Gemas ni pase en la beta", function()
		expect(Incubation.MaxSlots).toBe(5)
		expect(#Incubation.Slots).toBe(5)
		expect(Incubation.Slots[1].unlock).toBe("Start")
		expect(Incubation.Slots[3].price.Monedas).toBe(25000)
		expect(Incubation.Slots[4].price.Gemas).toBe(400)
		expect(Incubation.Slots[4].availableInBeta).toBe(false)
		expect(Incubation.Slots[5].availableInBeta).toBe(false)
	end)
end)

T.describe("Cofres (Genesis F2 §9)", function()
	T.it("los seis cofres de la Biblia, en orden de rango", function()
		expect(Chests.Order).toEqual({ "Madera", "Plata", "Oro", "Epico", "Diamante", "Nexo" })
		for i, id in ipairs(Chests.Order) do
			expect(Chests.ById[id].tier).toBe(i)
		end
	end)
	T.it("ningún cofre usa azar: las tablas de la Biblia compacta están incompletas", function()
		for _, id in ipairs(Chests.Order) do
			local def = Chests.ById[id]
			expect(def.mode).toBe("Fixed")
			expect(ChestRules.canUseRandom(id)).toBe(false)
		end
		local madera = ChestRules.validateTable(Chests.ById.Madera.bibleTable)
		expect(madera.ok).toBe(false)
		expect(madera.total).toBe(36) -- 30 % Común + 6 % Raro: falta el 64 %
	end)
	T.it("el validador acepta una tabla completa y detecta duplicados y faltantes", function()
		local good = ChestRules.validateTable({
			{ prize = "A", percent = 70, status = "Biblia" },
			{ prize = "B", percent = 30, status = "Biblia" },
		})
		expect(good.ok).toBe(true)
		local bad = ChestRules.validateTable({
			{ prize = "A", percent = 50, status = "Biblia" },
			{ prize = "A", percent = 40, status = "Biblia" },
			{ prize = "C", percent = nil, status = "Pendiente" },
		})
		expect(bad.ok).toBe(false)
		expect(#bad.issues >= 3).toBe(true)
	end)
	T.it("los activos tienen contenido fijo válido y grupos de huevos con modelo", function()
		for _, id in ipairs(Chests.Order) do
			local def = Chests.ById[id]
			if def.activeInBeta then
				expect(def.fixed ~= nil).toBe(true)
				for _, egg in ipairs(def.fixed.eggs) do
					expect(Chests.EggPools[egg.pool] ~= nil).toBe(true)
				end
				for _, entry in ipairs(def.fixed.codex or {}) do
					expect(Codex.ById[entry] ~= nil).toBe(true)
				end
			end
		end
		for rarity, pool in pairs(Chests.EggPools) do
			for _, sp in ipairs(pool) do
				expect(Species.ById[sp].rarity).toBe(rarity)
				expect(Visuals.ById[sp] ~= nil).toBe(true)
			end
		end
	end)
end)

T.describe("Tablón de Encargos (Biblia p. 13)", function()
	T.it("diarios de 150 a 250 Monedas, uno de cada dificultad disponible", function()
		local byDifficulty: { [string]: number } = {}
		for _, q in ipairs(Quests.Daily) do
			expect(q.coins >= 150 and q.coins <= 250).toBe(true)
			expect(q.target > 0).toBe(true)
			byDifficulty[q.difficulty] = (byDifficulty[q.difficulty] or 0) + 1
		end
		for _, d in ipairs(Quests.DailyMix) do
			expect((byDifficulty[d] or 0) >= 2).toBe(true)
		end
		expect(Quests.DailyCount).toBe(3)
		expect(Quests.DailyBonusChest).toBe("Madera")
		expect(#Quests.Weekly >= 1).toBe(true)
	end)
	T.it("los ids de encargo no se repiten", function()
		local seen = {}
		for _, list in ipairs({ Quests.Daily, Quests.Weekly }) do
			for _, q in ipairs(list) do
				expect(seen[q.id]).toBe(nil)
				seen[q.id] = true
			end
		end
	end)
end)

T.describe("Acto I · Valle Copal (Biblia p. 111–114)", function()
	T.it("tres regiones de cuatro etapas, una secreta por región y un jefe", function()
		expect(#Encounters.Regions).toBe(3)
		local numbered = 0
		for _, region in ipairs(Encounters.Regions) do
			expect(#region.stages).toBe(4)
			local secret = Encounters.ById[region.secret]
			expect(secret.stageType).toBe("Secreta")
			expect(secret.requiresRegionStars).toBe(region.index)
			numbered += #region.stages
		end
		expect(numbered).toBe(12)
		local boss = Encounters.ById[Encounters.Acts.ActoI.boss]
		expect(boss.stageType).toBe("Jefe")
		expect(boss.opponents[1].guardianId).toBe("copalia")
		expect(#Encounters.Order).toBe(16)
	end)
	T.it("premios de primera vez dentro de los rangos de la Biblia", function()
		for _, id in ipairs(Encounters.Order) do
			local enc = Encounters.ById[id]
			expect(enc.baseReward.Monedas >= 200 and enc.baseReward.Monedas <= 1500).toBe(true)
			expect(enc.baseReward.petXp >= 150 and enc.baseReward.petXp <= 800).toBe(true)
			if enc.firstClearChest then
				expect(Chests.ById[enc.firstClearChest].activeInBeta).toBe(true)
			end
			if enc.stageType == "Tesoro" then
				expect(enc.firstClearChest).toBe("Plata")
			end
			if enc.stageType == "Jefe" then
				expect(enc.firstClearChest).toBe("Nexo")
			end
			if enc.stageType == "Rescate" then
				expect(enc.rescue.eggChance).toBe(0.10)
			end
		end
	end)
	T.it("los acertijos de Tesoro tienen al menos una respuesta correcta y una incorrecta", function()
		for _, id in ipairs(Encounters.Order) do
			local enc = Encounters.ById[id]
			if enc.riddle then
				local right, wrong = 0, 0
				for _, el in ipairs(enc.riddle.options) do
					local eff = ElementChart.classify(ElementChart.multiplier(el, { enc.riddle.sealElement }, false))
					if eff == "Strong" then
						right += 1
					else
						wrong += 1
					end
				end
				expect(right >= 1).toBe(true)
				expect(wrong >= 1).toBe(true)
			end
		end
	end)
	T.it("los retos ★★★ varían entre etapas y sus referencias existen", function()
		local kinds = {}
		for _, id in ipairs(Encounters.Order) do
			local enc = Encounters.ById[id]
			kinds[enc.challenge.kind] = true
			expect(enc.mapPos[1] >= 0 and enc.mapPos[1] <= 1).toBe(true)
			expect(enc.mapPos[2] >= 0 and enc.mapPos[2] <= 1).toBe(true)
			for _, entry in ipairs(enc.firstClearCodex or {}) do
				expect(Codex.ById[entry] ~= nil).toBe(true)
			end
			if enc.firstClearDecor then
				expect(Decor.ById[enc.firstClearDecor] ~= nil).toBe(true)
			end
			for _, req in ipairs(enc.requires) do
				expect(Encounters.ById[req] ~= nil).toBe(true)
			end
		end
		local n = 0
		for _ in pairs(kinds) do
			n += 1
		end
		expect(n >= 4).toBe(true)
		for _, region in ipairs(Encounters.Regions) do
			expect(Decor.ById[region.clearDecor] ~= nil).toBe(true)
			expect(Codex.ById[region.clearCodex] ~= nil).toBe(true)
		end
	end)
	T.it("Pesadilla preparada pero desactivada", function()
		local n = Encounters.Acts.ActoI.nightmare
		expect(n.enabled).toBe(false)
		expect(n.levelBonus).toBe(10)
		expect(n.rewardScale).toBe(1.5)
	end)
end)

T.describe("Catálogo y Seres Sagrados", function()
	T.it("las 50 especies tienen ficha de lore", function()
		local n = 0
		for _, id in ipairs(Species.Order) do
			expect(SpeciesLore.ById[id] ~= nil).toBe(true)
			n += 1
		end
		expect(n).toBe(50)
	end)
	T.it("Copalia respeta el presupuesto Único (128) y su talento de la Biblia", function()
		local c = Guardians.ById.copalia
		local sum = c.stats.VID + c.stats.ATQ + c.stats.DEF + c.stats.ESE + c.stats.VEL
		expect(sum).toBe(Rarities.ById.Unico.statBudget)
		expect(c.rootHeal).toBe(0.06)
		expect(c.phases[1].effects[2].amount).toBe(-0.2)
	end)
end)
