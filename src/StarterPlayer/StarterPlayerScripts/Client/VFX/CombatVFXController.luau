--!strict
-- Secuencia visual de una jugada (Config/VFX.Sequences, Genesis §8):
-- preparación → anticipación → ejecución → impacto → reacción → recuperación.
-- * Ningún ataque supera 1,6 s; el Golpe Nexo como mucho 3,5 s (más la pausa de impacto,
--   que congela la imagen unas centésimas para que el golpe se lea).
-- * Todo se puede saltar: skip() termina al instante, pinta el impacto si aún no salió y
--   devuelve cada instancia al pool.
-- * Solo presentación: los eventos del servidor llegan ya resueltos y no se tocan.
-- Corre como un efecto del VFXRuntime (un paso por frame; reloj falso en las pruebas).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))

local VFXPlan = require(script.Parent.VFXPlan)
local VFXContext = require(script.Parent.VFXContext)
local VFXSettings = require(script.Parent.VFXSettings)
local ElementalVFXController = require(script.Parent.ElementalVFXController)
local ImpactVFXController = require(script.Parent.ImpactVFXController)

local CombatVFXController = {}

export type Side = { creature: any, anim: any?, aura: any?, uid: string? }
export type Spec = {
	move: any,
	attacker: Side,
	target: Side,
	events: { any }?, -- eventos de la jugada (Damage, Heal, Status…)
	camera: any?, -- CameraDirector
	sound: any?, -- SoundController (play(cueId, { at }))
	onPhase: ((phase: string, t: number) -> ())?,
	onImpact: ((events: { any }) -> ())?,
	runtime: any?,
	pool: any?,
	fast: boolean?,
	reducedMotion: boolean?,
	quality: string?,
}

local function cue(spec: Spec, id: string, at: Vector3?)
	if spec.sound then
		spec.sound:play(id, { at = at })
	end
end

-- Oscurece la escena durante el Golpe Nexo (luz y cámara)
local function dim(on: boolean, tint: any?)
	local existing = Lighting:FindFirstChild("NexoStrikeDim")
	if on and not existing and tint then
		local g = Instance.new("ColorCorrectionEffect")
		g.Name = "NexoStrikeDim"
		g.Brightness = tint.brightness
		g.Saturation = tint.saturation
		g.TintColor = Color3.fromRGB(tint.tint[1], tint.tint[2], tint.tint[3])
		g.Parent = Lighting
	elseif not on and existing then
		existing:Destroy()
	end
end

function CombatVFXController.play(spec: Spec): any
	local settings = VFXSettings.get()
	local reduced = if spec.reducedMotion ~= nil then spec.reducedMotion else settings.reducedMotion
	local move = spec.move
	local kind = VFXPlan.sequenceKind(move)
	local seqDef = (VFX.Sequences :: any)[kind]
	local tl = VFXPlan.timeline(kind, { fast = spec.fast or settings.fastBattle })
	local runtime = spec.runtime or VFXContext.runtime()
	local element = move.element
	local selfTarget = seqDef.selfTarget == true
	local target = if selfTarget then spec.attacker else spec.target
	local seq: any = {
		kind = kind,
		timeline = tl,
		t = 0,
		frozen = 0, -- pausa de impacto restante
		phase = nil :: string?,
		entered = {} :: { [string]: number },
		done = false,
		impacted = false,
		skipped = false,
		lunge = 0, -- studs hacia el objetivo (BattleController lo suma a la posición)
		lungeMax = (seqDef.lunge or 0) * (if reduced then 0.4 else 1),
	}
	local ctx = {
		owner = seq,
		runtime = runtime,
		pool = spec.pool,
		quality = spec.quality,
		reducedMotion = reduced,
		scale = spec.attacker.creature.scale or 1,
		element = element,
	}
	local function point(side: Side, anchor: string): Vector3
		return ElementalVFXController.point(side.creature, anchor)
	end

	local function impact()
		if seq.impacted then
			return
		end
		seq.impacted = true
		local result = { shake = 0, hitStop = 0, reaction = nil, sounds = {} }
		local events = spec.events or {}
		local any = false
		for _, e in ipairs(events) do
			local ids = VFXPlan.impactsFor(e, move)
			if #ids > 0 then
				any = true
				-- El impacto va a quien recibe el evento (el propio atacante en curas y escudos)
				local who = if e.target and e.target == spec.attacker.uid then spec.attacker else target
				local r = ImpactVFXController.play(
					ids,
					{ creature = who.creature, facing = point(spec.attacker, "Center") },
					ctx
				)
				result.shake = math.max(result.shake, r.shake)
				result.hitStop = math.max(result.hitStop, r.hitStop)
				result.reaction = r.reaction or result.reaction
				for _, s in ipairs(r.sounds) do
					table.insert(result.sounds, s)
				end
			end
		end
		if not any then
			-- Sin eventos (o solo de estado): el impacto del elemento sobre el objetivo
			ElementalVFXController.layer(element, "impact", { creature = target.creature }, ctx)
		end
		if not seq.skipped then
			seq.frozen = result.hitStop
			if spec.camera then
				spec.camera:shake(result.shake, 0.25)
			end
			if target.anim and result.reaction then
				target.anim:trigger(result.reaction)
			end
		end
		cue(spec, "SFX_" .. (element or "Eco") .. "_Impact", point(target, "Center"))
		for _, s in ipairs(result.sounds) do
			cue(spec, s, point(target, "Center"))
		end
		if spec.onImpact then
			spec.onImpact(events)
		end
	end

	local handlers: { [string]: () -> () } = {
		Preparation = function()
			if spec.attacker.anim then
				spec.attacker.anim:trigger(seqDef.animator, tl.total, seqDef.variant)
			end
			if spec.attacker.aura then
				spec.attacker.aura:setAttacking(true)
			end
			if kind == "Nexo" then
				if not reduced then
					dim(true, seqDef.dim)
					seq.dimmed = true
				end
				if spec.camera then
					spec.camera:beat("Nexo", point(spec.attacker, "Center"), tl.total * 0.7)
				end
				cue(spec, "SFX_Combat_NexoCharge", point(spec.attacker, "Center"))
			end
		end,
		Anticipation = function()
			ElementalVFXController.layer(
				element,
				"cast",
				{ creature = spec.attacker.creature, facing = point(target, "Center") },
				ctx
			)
			if spec.camera and seqDef.camera.anticipation then
				spec.camera:beat(seqDef.camera.anticipation, point(spec.attacker, "Center"))
			end
			cue(spec, "SFX_" .. (element or "Eco") .. "_Cast", point(spec.attacker, "Mouth"))
		end,
		Execution = function()
			if not selfTarget then
				local p0 = point(spec.attacker, "Mouth")
				local p1 = point(target, "Center")
				local exec = tl.phases[3].duration
				local travel = ElementalVFXController.travelTime(element, (p1 - p0).Magnitude, exec)
				local tctx = table.clone(ctx) :: any
				tctx.feet0 = point(spec.attacker, "Feet")
				tctx.feet1 = point(target, "Feet")
				ElementalVFXController.travel(element, p0, p1, travel, tctx)
			end
			cue(spec, "SFX_" .. (element or "Eco") .. "_Travel", point(spec.attacker, "Mouth"))
		end,
		Impact = function()
			if spec.camera and seqDef.camera.impact then
				spec.camera:beat(seqDef.camera.impact, point(target, "Center"))
			end
			impact()
		end,
		Reaction = function() end,
		Recovery = function()
			if spec.attacker.aura then
				spec.attacker.aura:setAttacking(false)
			end
			dim(false)
			seq.dimmed = false
		end,
	}

	local function enter(phase: string)
		if seq.entered[phase] then
			return
		end
		seq.entered[phase] = seq.t
		seq.phase = phase
		handlers[phase]()
		if spec.onPhase then
			spec.onPhase(phase, seq.t)
		end
	end

	local function finish()
		if seq.done then
			return
		end
		seq.done = true
		seq.phase = "Done"
		seq.lunge = 0
		if spec.attacker.aura then
			spec.attacker.aura:setAttacking(false)
		end
		dim(false)
		seq.dimmed = false
	end

	function seq.skip()
		if seq.done then
			return
		end
		seq.skipped = true
		-- El impacto (y las cifras que dependen de él) sale una vez aunque se salte
		impact()
		runtime:cancelOwner(seq)
		local pool = spec.pool or VFXContext.pool()
		pool:releaseOwner(seq)
		if spec.camera then
			spec.camera:clear()
		end
		seq.t = tl.total
		finish()
		if spec.onPhase then
			spec.onPhase("Done", seq.t)
		end
	end

	function seq.reached(phase: string): boolean
		return seq.done or seq.entered[phase] ~= nil
	end

	local function step(dt: number): boolean
		if seq.done then
			return false
		end
		if seq.frozen > 0 then
			-- Pausa de impacto: la imagen se congela un instante (se lee congelada)
			seq.frozen -= dt
			return true
		end
		seq.t += dt
		local phase = VFXPlan.phaseAt(tl, seq.t)
		-- Entra en todas las fases que se hayan cruzado en este paso (un frame largo no se salta ninguna)
		for _, slot in ipairs(tl.phases) do
			if seq.t >= slot.start and not seq.entered[slot.id] then
				enter(slot.id)
			end
		end
		-- Embestida: sube en la ejecución y vuelve en la reacción
		local exec, react = tl.phases[3], tl.phases[5]
		local u = math.clamp((seq.t - exec.start) / (react.start + react.duration - exec.start), 0, 1)
		seq.lunge = seq.lungeMax * math.sin(math.pi * u)
		if phase == "Done" then
			finish()
			if spec.onPhase then
				spec.onPhase("Done", seq.t)
			end
			return false
		end
		return true
	end

	seq.step = step
	enter("Preparation")
	runtime:add({
		update = function(_, dt: number)
			return step(dt)
		end,
		finish = function()
			if not seq.done then
				seq.skip()
			end
		end,
	})
	return seq
end

return CombatVFXController
