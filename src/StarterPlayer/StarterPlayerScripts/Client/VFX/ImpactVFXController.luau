--!strict
-- Biblioteca de impactos (Config/VFX.Impacts): físico, elemental, escudo, curación,
-- quemadura, parálisis, aturdimiento, reflejo, crítico y victoria. Pinta el impacto en el
-- objetivo y devuelve lo que la secuencia debe hacer después (sacudida, pausa de impacto,
-- reacción del animador y sonido). La sacudida nunca pasa de VFX.Camera.maxShake.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))

local VFXPlan = require(script.Parent.VFXPlan)
local ElementalVFXController = require(script.Parent.ElementalVFXController)

local ImpactVFXController = {}

export type Result = { shake: number, hitStop: number, reaction: string?, sounds: { string } }

-- impactIds: lista (p. ej. { "Elemental", "Crit" }). target: { creature } o { position }.
function ImpactVFXController.play(impactIds: { string }, target: any, ctx: any?): Result
	local c = ctx or {}
	local profile = VFXPlan.profile(c.element)
	local result: Result = { shake = 0, hitStop = 0, reaction = nil, sounds = {} }
	for _, id in ipairs(impactIds) do
		local imp = (VFX.Impacts :: any)[id]
		if imp then
			if imp.useElement then
				ElementalVFXController.layer(c.element, "impact", target, c)
				result.shake = math.max(result.shake, (profile.shake or 0.5) * imp.shake * 2)
			end
			local layer = { emitters = imp.emitters, rings = imp.rings, light = imp.light, flash = imp.flash }
			-- Las capas de la biblioteca usan sus colores fijos (curación verde, crítico dorado…)
			local fixed = { palette = profile.palette }
			ImpactVFXController._layer(layer, target, fixed, c)
			if imp.arcs then
				local center = if target.creature
					then ElementalVFXController.point(target.creature, "Center")
					else target.position
				ElementalVFXController.arcs(imp.arcs, center, fixed, c)
			end
			result.shake = math.max(result.shake, imp.shake)
			result.hitStop = math.max(result.hitStop, imp.hitStop or 0)
			result.reaction = imp.reaction or result.reaction
			table.insert(result.sounds, imp.sound)
		end
	end
	result.shake = math.min(result.shake, VFX.Camera.maxShake)
	return result
end

-- Capa ad hoc (misma forma que las capas de los elementos)
function ImpactVFXController._layer(layer: any, target: any, colors: any, ctx: any)
	local creature = target.creature
	for _, use in ipairs(layer.emitters or {}) do
		local pos = if creature then ElementalVFXController.point(creature, use.anchor) else target.position
		ElementalVFXController.burst(use, pos, target.facing, colors, ctx)
	end
	local center = if creature then ElementalVFXController.point(creature, "Center") else target.position
	local feet = if creature then ElementalVFXController.point(creature, "Feet") else target.position
	for _, ring in ipairs(layer.rings or {}) do
		ElementalVFXController.ring(
			ring,
			if (ring.tilt or 0) == 0 then feet + Vector3.new(0, 0.08, 0) else center,
			colors,
			ctx
		)
	end
	if layer.light then
		ElementalVFXController.light(layer.light, center, colors, ctx)
	end
	if layer.flash and creature then
		ElementalVFXController.flash(layer.flash, creature.model, colors, ctx)
	end
end

-- Atajo: impactos de un evento del servidor (VFXPlan.impactsFor) sobre una criatura
function ImpactVFXController.forEvent(e: any, move: any?, creature: any, ctx: any?): Result
	return ImpactVFXController.play(VFXPlan.impactsFor(e, move), { creature = creature }, ctx)
end

return ImpactVFXController
