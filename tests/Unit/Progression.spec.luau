--!strict
local T = harness.T
local expect = T.expect
local Leveling = harness.get("ReplicatedStorage.Shared.Domain.Leveling")
local Stats = harness.get("ReplicatedStorage.Shared.Domain.Stats")

T.describe("Curva de XP 40 × L^1.5 (p. 115)", function()
	-- Valores publicados en la Biblia; el redondeo por nivel admite ±3 XP.
	local published =
		{ [12] = 7166, [15] = 12799, [18] = 20487, [20] = 26855, [22] = 34282, [25] = 47525, [50] = 275808 }
	for level, xp in pairs(published) do
		T.it(string.format("nivel %d ≈ %d XP acumulada", level, xp), function()
			expect(Leveling.totalXpForLevel(level)).toBeNear(xp, 3)
		end)
	end

	T.it("sube varios niveles con una sola concesión y conserva el sobrante", function()
		local r = Leveling.addXp(1, 0, Leveling.xpToNext(1) + Leveling.xpToNext(2) + 5)
		expect(r.level).toBe(3)
		expect(r.xp).toBe(5)
		expect(r.levelsGained).toBe(2)
	end)

	T.it("se detiene en el tope 50 y descarta el sobrante", function()
		local r = Leveling.addXp(49, 0, 10 ^ 7)
		expect(r.level).toBe(50)
		expect(r.xp).toBe(0)
		expect(r.overflowDiscarded).toBeGreaterThan(0)
	end)

	T.it("rechaza XP negativa", function()
		expect(function()
			Leveling.addXp(1, 0, -5)
		end).toThrow()
	end)
end)

T.describe("Tallado y Vínculo", function()
	T.it("un Común se talla a nivel 12 con 2 corazones de Vínculo", function()
		local ok, reason = Leveling.canEvolve({ speciesId = "kuachi", form = "Brote", level = 11, bond = 50 })
		expect(ok).toBe(false)
		expect(reason).toBe("LevelTooLow")
		ok, reason = Leveling.canEvolve({ speciesId = "kuachi", form = "Brote", level = 12, bond = 0 })
		expect(ok).toBe(false)
		expect(reason).toBe("BondTooLow")
		ok = Leveling.canEvolve({ speciesId = "kuachi", form = "Brote", level = 12, bond = 8 })
		expect(ok).toBe(true)
	end)

	T.it("un Tallado no se vuelve a tallar", function()
		local ok, reason = Leveling.canEvolve({ speciesId = "kuachi", form = "Tallado", level = 30, bond = 99 })
		expect(ok).toBe(false)
		expect(reason).toBe("AlreadyTallado")
	end)

	T.it("el próximo objetivo guía al jugador", function()
		local o = Leveling.nextObjective({ speciesId = "teselo", form = "Brote", level = 3, xp = 0, bond = 0 })
		expect(o.kind).toBe("ReachTalladoLevel")
		expect(o.target).toBe(12)
		o = Leveling.nextObjective({ speciesId = "teselo", form = "Brote", level = 12, xp = 0, bond = 0 })
		expect(o.kind).toBe("BondForTallado")
		o = Leveling.nextObjective({ speciesId = "teselo", form = "Tallado", level = 12, xp = 0, bond = 9 })
		expect(o.kind).toBe("ReachNexoLevel")
	end)
end)

T.describe("Atributos (p. 35)", function()
	T.it("factor de nivel: 41 % a nivel 1, 70 % a nivel 25 y 100 % a nivel 50", function()
		expect(Stats.levelFactor(1)).toBeNear(0.412)
		expect(Stats.levelFactor(25)).toBeNear(0.70)
		expect(Stats.levelFactor(50)).toBeNear(1.0)
	end)

	T.it("el Brote usa el 70 % de la base del Tallado", function()
		local b = Stats.formBase("kuachi", "Brote")
		-- Ficha de Kuachi (p. 49): VID 13, ATQ 20, DEF 10, ESE 13, VEL 14
		expect(b.VID).toBe(13)
		expect(b.ATQ).toBe(20)
		expect(b.DEF).toBe(10)
		expect(b.ESE).toBe(13)
		expect(b.VEL).toBe(14)
	end)

	T.it("PV = VID × 10 a nivel 50 en Tallado", function()
		local s = Stats.effective("xolumi", "Tallado", 50)
		expect(Stats.maxHp(s.VID)).toBe(240)
	end)
end)
