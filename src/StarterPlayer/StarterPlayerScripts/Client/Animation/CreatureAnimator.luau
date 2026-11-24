--!strict
-- Animación procedural de criaturas por familia anatómica y personalidad
-- (Config/CreatureMotion; docs/ANIMATION_SYSTEM.md).
--
-- Cada frame calcula un DELTA por hueso lógico (spine/body, chest, neck, head, jaw,
-- legF_L…, pawF_*, tail1..5, gill_*, wing_*, ringA, ringB, skyDisc) alrededor de su
-- articulación, más el movimiento del cuerpo entero (rebote, inclinación, salto). El mismo
-- delta se aplica a:
-- * el BLOCKOUT de Parts: las piezas de cada hueso giran alrededor de su pivote y se
--   mueven con una sola llamada a BulkMoveTo (o CFrame directo dentro de un ViewportFrame);
-- * el MODELO IMPORTADO con huesos: Bone.Transform por nombre (los nombres son los de
--   assets/Creatures/*/asset.json) y el modelo entero con PivotTo.
-- Respiración, mirada y giro de cabeza, cola (en espiral en Kuachi), ciclo de pasos y
-- rebote según la velocidad, inclinación en los giros, frenada, salto, caída y aterrizaje,
-- y las poses de los estados (ataque, daño, aturdido, victoria, cansancio…).
-- LOD: "Reduced" anima a la mitad de frecuencia; "None" no hace nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local CreatureMotion = require(Config:WaitForChild("CreatureMotion"))

local MotionStateMachine = require(script.Parent.MotionStateMachine)
local CreatureRig = require(script.Parent.Parent.Creatures.CreatureRig)

local CreatureAnimator = {}
CreatureAnimator.__index = CreatureAnimator

local TAU = math.pi * 2
local GRAVITY = CreatureMotion.Thresholds.gravity

-- Desfase del ciclo de pasos por pata y por forma de andar
local GAIT_OFFSETS: { [string]: { [string]: number } } = {
	Trot = {
		legF_L = 0,
		legB_R = 0,
		legF_R = math.pi,
		legB_L = math.pi,
		legM_L = math.pi / 2,
		legM_R = 3 * math.pi / 2,
	},
	Sprawl = { legF_L = 0, legB_R = 0, legF_R = math.pi, legB_L = math.pi, legM_L = math.pi, legM_R = 0 },
	Plod = {
		legF_L = 0,
		legB_R = math.pi / 2,
		legF_R = math.pi,
		legB_L = 3 * math.pi / 2,
		legM_L = math.pi / 4,
		legM_R = 5 * math.pi / 4,
	},
	Stride = { legB_L = 0, legB_R = math.pi, legM_L = 0, legM_R = math.pi, legF_L = math.pi, legF_R = 0 },
	Hop = { legB_L = 0, legB_R = 0, legM_L = 0, legM_R = 0, legF_L = 0, legF_R = 0 },
	Hover = { legB_L = 0, legB_R = 0.6, legM_L = 0.3, legM_R = 0.9, legF_L = 1.2, legF_R = 1.8 },
}

export type Motion = {
	speed: number,
	yawRate: number?,
	groundY: number?, -- para detectar caídas de altura (bajar un escalón)
}

local function smooth(cur: number, target: number, rate: number, dt: number): number
	return cur + (target - cur) * (1 - math.exp(-rate * dt))
end

local function ease(u: number): number
	local x = math.clamp(u, 0, 1)
	return x * x * (3 - 2 * x)
end

local function sideOf(name: string): number
	return if string.sub(name, -2) == "_L" then 1 else -1
end

-- creature: blockout de CreatureBuilder (con .parts) o { model, speciesId, form, scale }
-- de un modelo importado con huesos (opts.mesh = true).
function CreatureAnimator.new(
	creature: any,
	opts: { seed: number?, rig: any?, mesh: boolean?, speciesId: string? }?
): any
	local o = opts or {}
	local scale = creature.scale or 1
	local rig = o.rig
		or (
			if o.mesh
					or creature.mesh
					or not creature.parts
				then CreatureRig.fromBones(creature.model, scale)
				else CreatureRig.get(creature)
		)
	local speciesId = o.speciesId or creature.speciesId
	local profile = MotionStateMachine.profile(speciesId)
	local self = setmetatable({
		creature = creature,
		rig = rig,
		mesh = rig.kind == "Bones",
		profile = profile,
		scale = scale,
		sm = MotionStateMachine.new(profile, o.seed or math.floor((creature.phase or 1) * 1000) + 1),
		t = creature.phase or 0,
		gait = 0,
		legAmt = 0,
		p = {
			y = 0,
			z = 0,
			pitch = 0,
			roll = 0,
			headYaw = 0,
			headPitch = 0,
			headRoll = 0,
			headBack = 0,
			tuck = 0,
			jaw = 0,
		},
		look = nil :: Vector3?,
		airY = 0,
		airVY = 0,
		lastGround = nil :: number?,
		jumpQueued = false,
		skip = false,
		acc = 0,
		applied = 0,
		deltas = {} :: { [string]: CFrame },
		parts = {} :: { BasePart },
		cfs = {} :: { CFrame },
		recs = {} :: { any },
	}, CreatureAnimator)
	-- Lista fija de piezas por hueso (BulkMoveTo de una sola vez)
	if not self.mesh then
		for _, rec in ipairs(creature.parts) do
			local bone = rec.part:GetAttribute("Bone")
			table.insert(self.recs, { rec = rec, bone = if rig.bones[bone] then bone else nil })
			table.insert(self.parts, rec.part)
		end
	end
	return self
end

function CreatureAnimator.setLookTarget(self: any, worldPos: Vector3?)
	self.look = worldPos
end

function CreatureAnimator.trigger(self: any, state: string, duration: number?, variant: string?)
	self.sm:trigger(state, duration, variant)
end

function CreatureAnimator.hold(self: any, state: string?, variant: string?)
	self.sm:hold(state, variant)
end

function CreatureAnimator.jump(self: any)
	self.jumpQueued = true
end

function CreatureAnimator.state(self: any): string
	return self.sm.state
end

-- Objetivos de pose del estado actual (antes del suavizado)
local function stateTargets(self: any, root: CFrame): { [string]: number }
	local prof = self.profile
	local s = self.scale
	local sm = self.sm
	local st, v, time = sm.state, sm.variant, sm.time
	local dur = math.max(0.05, if st == "IdleAlt" then sm.idleLength else sm.duration)
	local u = math.clamp(time / dur, 0, 1)
	local tg =
		{ y = 0, z = 0, pitch = 0, roll = 0, headYaw = 0, headPitch = 0, headRoll = 0, headBack = 0, tuck = 0, jaw = 0 }
	-- Mirada: hacia el objetivo si lo hay
	if self.look then
		local lp = root:PointToObjectSpace(self.look)
		local headY = self.rig.anchors.head.Y
		tg.headYaw = math.clamp(math.atan2(lp.X, lp.Z), -prof.headYaw, prof.headYaw)
		local flat = math.sqrt(lp.X * lp.X + lp.Z * lp.Z)
		tg.headPitch = math.clamp(-math.atan2(lp.Y - headY, math.max(0.5, flat)), -prof.headPitch, prof.headPitch)
	end
	if st == "Run" then
		tg.pitch = prof.pitchRun
	elseif st == "Walk" then
		tg.pitch = prof.pitchRun * 0.3
	elseif st == "Stop" then
		tg.pitch = -0.12
		tg.y = -prof.landSquash * 0.5 * s
	elseif st == "Land" then
		tg.y = -prof.landSquash * s
		tg.pitch = 0.06
	elseif st == "Jump" then
		tg.pitch = -0.15
	elseif st == "Fall" then
		tg.pitch = 0.1
	elseif st == "IdleAlt" then
		if v == "LookAround" then
			tg.headYaw = math.sin(time * 1.6) * prof.headYaw
		elseif v == "Sniff" then
			tg.headPitch = 0.15 + 0.06 * math.sin(time * TAU * (prof.sniffHz or 5))
			tg.headYaw = 0.25 * math.sin(time * 1.3)
			tg.z = 0.04 * s
		elseif v == "Shake" then
			tg.roll = 0.15 * math.sin(time * 25) * (1 - u)
		elseif v == "Rest" then
			tg.y = -0.06 * s
			tg.headPitch = 0.15
		elseif v == "Retreat" then
			tg.headBack, tg.tuck = 1, 1
		elseif v == "Preen" then
			tg.headYaw, tg.headPitch, tg.headRoll = 0.9, 0.3, 0.3
		elseif v == "Loop" then
			tg.roll = TAU * ease(u)
			tg.y = 0.2 * s * math.sin(math.pi * u)
		end
	elseif st == "Interact" then
		tg.headRoll, tg.headPitch = 0.25, 0.2
		tg.y = math.abs(math.sin(time * 6)) * 0.06 * s
	elseif st == "Eat" then
		tg.headPitch = 0.35 + 0.12 * math.sin(time * 12)
		tg.jaw = 0.5 + 0.5 * math.sin(time * 12)
	elseif st == "Happy" then
		if v == "PlayDead" then
			-- «Se hace el muerto»: se tumba de lado, aguanta y se levanta de un salto
			local down = ease(time / 0.3) * (1 - ease((time - (dur - 0.35)) / 0.35))
			tg.roll = 1.45 * down
			tg.y = -0.1 * s * down
			tg.headPitch = 0.1
		else
			tg.y = math.abs(math.sin(time * 9)) * 0.25 * s
			tg.headPitch = -0.2
		end
	elseif st == "Curious" then
		tg.headRoll, tg.headPitch, tg.z = 0.35, -0.1, 0.1 * s
	elseif st == "Warn" then
		if v == "Retreat" then
			tg.headBack, tg.tuck = 1, 1
		else
			tg.y, tg.pitch, tg.headPitch = -0.08 * s, 0.1, 0.15
		end
	elseif st == "Hurt" then
		local k = 1 - u
		tg.z, tg.pitch = -0.25 * s * k, -0.2 * k
		tg.roll = 0.12 * math.sin(time * 30) * k
	elseif st == "Stun" then
		tg.roll = 0.14 * math.sin(time * 5)
		tg.headPitch, tg.headRoll = 0.25, 0.15 * math.sin(time * 5 + 1)
	elseif st == "Victory" then
		tg.y = math.abs(math.sin(time * 7)) * 0.3 * s
		tg.headPitch = -0.25
	elseif st == "Defeat" then
		-- Cansado, nunca dramático (público de 9 a 16 años)
		tg.pitch, tg.y, tg.headPitch = 0.22, -0.12 * s, 0.4
	elseif st == "Attack" then
		if u < 0.35 then
			tg.pitch, tg.z = -0.15, -0.15 * s
		elseif u < 0.6 then
			tg.pitch, tg.z, tg.headPitch, tg.jaw = 0.18, 0.35 * s, 0.15, 1
		end
	elseif st == "Special" then
		if v == "Guard" and prof.defend == "Retreat" then
			tg.headBack, tg.tuck = 1, 1
		elseif v == "Guard" then
			tg.y, tg.pitch = -0.08 * s, -0.1
		else
			tg.pitch = -0.25 * math.sin(math.pi * u)
			tg.y = 0.12 * s * math.sin(math.pi * u)
			tg.jaw = math.sin(math.pi * u)
		end
	elseif st == "Nexo" then
		if u < 0.45 then
			tg.y, tg.pitch = -0.1 * s, -0.1
			tg.roll = 0.05 * math.sin(time * 40)
		elseif u < 0.65 then
			tg.y, tg.pitch, tg.jaw = 0.3 * s, 0.2, 1
		end
	end
	return tg
end

-- Calcula el cuerpo (base) y los deltas por hueso. Devuelve la base.
function CreatureAnimator.pose(self: any, dt: number, root: CFrame, motion: Motion): CFrame
	local prof = self.profile
	local s = self.scale
	local speed = motion.speed
	local yawRate = motion.yawRate or 0
	self.t += dt
	local t = self.t
	local tempo = prof.tempo or 1

	-- Salto y caída (simulación vertical propia; el suelo lo da quien llama)
	if motion.groundY then
		if self.lastGround and self.lastGround - motion.groundY > 0.5 then
			self.airY += self.lastGround - motion.groundY -- bajó un escalón: cae desde arriba
		end
		self.lastGround = motion.groundY
	end
	if self.jumpQueued then
		self.jumpQueued = false
		if self.airY <= 0 then
			self.airVY = math.sqrt(2 * GRAVITY * prof.jumpHeight * s)
		end
	end
	local grounded = self.airY <= 0 and self.airVY <= 0
	if not grounded then
		self.airVY -= GRAVITY * dt
		self.airY += self.airVY * dt
		if self.airY <= 0 then
			self.airY, self.airVY = 0, 0
		end
	end
	self.sm:update(dt, { speed = speed, verticalSpeed = self.airVY, grounded = grounded, yawRate = yawRate })

	-- Ciclo de pasos según la velocidad
	local ref = prof.walkRef
	if speed > 0.2 and prof.stepHz > 0 then
		self.gait += dt * TAU * prof.stepHz * tempo * math.clamp(speed / ref, 0.6, 2.2)
	end
	self.legAmt = smooth(self.legAmt, math.clamp(speed / ref, 0, 1.4), 10, dt)
	local amt = self.legAmt
	local g = self.gait
	local running = self.sm.state == "Run"

	-- Suavizado de la pose del estado
	local tg = stateTargets(self, root)
	local p = self.p
	for k, v in pairs(tg) do
		local rate = if string.sub(k, 1, 4) == "head" then prof.headSpeed * tempo else 14
		p[k] = smooth(p[k], v, rate, dt)
	end

	-- Cuerpo entero: rebote por forma de andar, flotación, inclinación en giros
	local gaitBob = 0
	local gait = prof.gait
	if gait == "Plod" then
		gaitBob = -(prof.plant or 0) * s * math.max(0, math.cos(2 * g)) * amt
	elseif gait == "Hover" then
		gaitBob = (prof.hoverHeight or 0) * s + prof.hover * s * math.sin(t * TAU * (prof.hoverHz or 1))
	else
		gaitBob = math.abs(math.sin(g)) * (if running then prof.runBob else prof.bob) * s * math.min(1, amt)
	end
	local lean = math.clamp(-yawRate * speed * 0.02, -prof.lean, prof.lean)
	local cy = self.rig.anchors.center.Y
	local base = root
		* CFrame.new(0, cy, 0)
		* CFrame.Angles(p.pitch, 0, p.roll + lean)
		* CFrame.new(0, -cy + gaitBob + p.y + self.airY, p.z)

	-- Deltas por hueso
	local d = self.deltas
	table.clear(d)
	local breath = math.sin(t * TAU * prof.breathHz * tempo) * prof.breathAmp * s
	local und = (prof.undulate or 0) * (math.sin(g) * amt + 0.2 * math.sin(t * 0.8))
	local torso = self.rig.torso
	d[torso] = CFrame.new(0, breath, 0) * CFrame.Angles(0, und, 0)
	d.chest = CFrame.Angles(-breath * 0.5, 0, 0)
	local hasNeck = self.rig.bones.neck ~= nil
	local headShare = if hasNeck then 0.6 else 1
	if hasNeck then
		d.neck = CFrame.Angles(p.headPitch * 0.4, p.headYaw * 0.4, 0)
	end
	d.head = CFrame.new(0, -p.headBack * 0.15 * s, -p.headBack * 0.45 * s)
		* CFrame.Angles(p.headPitch * headShare, p.headYaw * headShare - und * 0.8, p.headRoll)
	d.jaw = CFrame.Angles(0.25 * p.jaw, 0, 0)
	-- Patas
	local offsets = GAIT_OFFSETS[gait] or GAIT_OFFSETS.Trot
	for name in pairs(offsets) do
		if self.rig.bones[name] then
			local ph = g + offsets[name]
			local swing
			if gait == "Hover" then
				swing = 0.15 * math.sin(t * 2 + offsets[name])
			elseif gait == "Plod" then
				swing = prof.stride * amt * math.clamp(math.sin(ph) * 1.5, -1, 1) -- apoyos largos
			else
				swing = prof.stride * amt * math.sin(ph)
			end
			local sprawl = if gait == "Sprawl" then 0.25 * sideOf(name) * math.sin(ph) * amt else 0
			d[name] = CFrame.new(0, p.tuck * 0.22 * s, 0) * CFrame.Angles(swing, sprawl, 0)
			local paw = "paw" .. string.sub(name, 4)
			if self.rig.bones[paw] then
				d[paw] = CFrame.Angles(-swing * 0.5, 0, 0)
			end
		end
	end
	-- Cola (en espiral si la especie la tiene)
	local state = self.sm.state
	local wag = if state == "Happy" or state == "Victory" then 2.2 else 1
	local curl = if self.sm.variant == "TailCurl" then 1.8 else 1
	local tailAmp = (prof.tailAmp or 0) * curl
	local tailPh = t * TAU * prof.tailHz * tempo * wag
	local n = 0
	for i = 1, 5 do
		if self.rig.bones["tail" .. i] then
			n = i
		end
	end
	for k = 1, n do
		local w = 0.5 + k / math.max(1, n)
		local yaw = tailAmp * w * math.sin(tailPh - k * 0.7) / math.max(1, n) * 2
		local pitch = if prof.tailSpiral
			then tailAmp * 0.6 * w * math.cos(tailPh - k * 0.7) / math.max(1, n) * 2
			else (if speed > 1 then -0.05 else 0)
		d["tail" .. k] = CFrame.Angles(pitch, yaw + und * 0.6, 0)
	end
	-- Branquias que laten
	if (prof.gillAmp or 0) > 0 then
		local pulse = if self.sm.variant == "GillPulse" then 2 else 1
		local flare = prof.gillAmp * pulse * (0.5 + 0.5 * math.sin(t * TAU * prof.gillHz * tempo))
		d.gill_L = CFrame.Angles(0, 0, -flare)
		d.gill_R = CFrame.Angles(0, 0, flare)
	end
	-- Alas
	if (prof.wingAmp or 0) > 0 then
		local active = if gait == "Hover"
			then 0.6
			elseif speed > 1 or not grounded or self.sm.variant == "Flap" then 1
			else 0.1
		local flap = prof.wingAmp * active * math.sin(t * TAU * prof.wingHz)
		d.wing_L = CFrame.Angles(0, 0, -flap)
		d.wing_R = CFrame.Angles(0, 0, flap)
	end
	-- Mitlaxis: terrazas que giran y disco de cielo que se mece
	d.ringA = CFrame.Angles(0, t * 0.4, 0)
	d.ringB = CFrame.Angles(0, -t * 0.3, 0)
	d.skyDisc = CFrame.Angles(0.05 * math.sin(t * 0.7), 0, 0.05 * math.sin(t * 0.5))
	return base
end

local function applyParts(self: any, base: CFrame)
	local rig = self.rig
	local world: { [string]: CFrame } = {}
	for _, name in ipairs(rig.order) do
		local b = rig.bones[name]
		local parentW = if b.parent and world[b.parent] then world[b.parent] else base
		local delta = self.deltas[name]
		world[name] = if delta then parentW * CFrame.new(b.pivot) * delta * CFrame.new(-b.pivot) else parentW
	end
	local t = self.t
	local cfs = self.cfs
	for i, entry in ipairs(self.recs) do
		local rec = entry.rec
		local w = if entry.bone then world[entry.bone] else base
		local cf = w * rec.offset
		if rec.kind == "SpinZ" then
			cf *= CFrame.Angles(0, -t * 0.9, 0)
		elseif rec.kind == "SpinY" then
			cf *= CFrame.Angles(0, t * 0.4, 0)
		end
		cfs[i] = cf
	end
	local model = self.creature.model
	if model:IsDescendantOf(workspace) then
		workspace:BulkMoveTo(self.parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	else
		-- ViewportFrame o fuera del mundo: BulkMoveTo solo aplica en Workspace
		for i, part in ipairs(self.parts) do
			part.CFrame = cfs[i]
		end
	end
end

local function applyBones(self: any, base: CFrame)
	for name, b in pairs(self.rig.bones) do
		local inst = b.instance
		if inst then
			(inst :: any).Transform = self.deltas[name] or CFrame.identity
		end
	end
	pcall(function()
		self.creature.model:PivotTo(base)
	end)
end

-- Un paso. lod: "Full" (cada frame) · "Reduced" (la mitad) · "None" (nada).
-- Devuelve true si movió la criatura en este frame.
function CreatureAnimator.update(self: any, dt: number, root: CFrame, motion: Motion, lod: string?): boolean
	if lod == "None" then
		return false
	end
	self.acc += dt
	if lod == "Reduced" then
		self.skip = not self.skip
		if self.skip then
			return false
		end
	end
	local step = self.acc
	self.acc = 0
	local base = self:pose(step, root, motion)
	if self.mesh then
		applyBones(self, base)
	else
		applyParts(self, base)
	end
	self.applied += 1
	return true
end

return CreatureAnimator
