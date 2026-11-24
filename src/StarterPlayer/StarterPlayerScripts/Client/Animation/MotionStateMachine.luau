--!strict
-- Máquina de estados de animación (lógica PURA: sin APIs de motor; el reloj y el Rng los
-- da quien la usa). Estados en Config/CreatureMotion.States.
-- Prioridad: estado fijado (hold: Stun, Defeat, Victory…) > estado de un solo uso
-- (Attack, Hurt, Happy…) > aire (Jump, Fall, Land) > locomoción (Idle, IdleAlt, Walk, Run,
-- Turn, Stop). La locomoción usa histéresis para no vibrar cerca de los umbrales.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CreatureMotion = require(Shared:WaitForChild("Config"):WaitForChild("CreatureMotion"))
local Species = require(Shared.Config:WaitForChild("Species"))
local Rng = require(Shared:WaitForChild("Domain"):WaitForChild("Rng"))

local MotionStateMachine = {}
MotionStateMachine.__index = MotionStateMachine

export type Input = { speed: number, verticalSpeed: number?, grounded: boolean?, yawRate: number? }

-- Perfil de movimiento: familia + personalidad de la especie (si la tiene)
function MotionStateMachine.familyFor(speciesId: string): string
	local personal = CreatureMotion.Species[speciesId]
	if personal then
		return personal.family
	end
	local guardian = CreatureMotion.GuardianFamily[speciesId]
	if guardian then
		return guardian
	end
	local sp = Species.ById[speciesId]
	if sp then
		local fam = CreatureMotion.FamilyBySpecies[sp.family] or "QuadrupedAgile"
		if fam == "QuadrupedAgile" and sp.family == "Cuadrúpedo" and CreatureMotion.HeavyRoles[sp.role] then
			return "QuadrupedHeavy"
		end
		return fam
	end
	return "QuadrupedAgile"
end

function MotionStateMachine.profile(speciesId: string): { [string]: any }
	local fam = CreatureMotion.Families[MotionStateMachine.familyFor(speciesId)]
	local out: { [string]: any } = table.clone(fam :: any)
	out.tempo = 1
	out.inertia = 1
	out.speciesId = speciesId
	local personal = CreatureMotion.Species[speciesId]
	if personal then
		for k, v in pairs(personal) do
			out[k] = v
		end
	end
	return out
end

export type Machine = typeof(setmetatable(
	{} :: {
		profile: { [string]: any },
		rng: any,
		state: string,
		variant: string?,
		time: number, -- tiempo en el estado actual
		duration: number, -- duración del estado de un solo uso o del IdleAlt
		loco: string,
		holdState: string?,
		holdVariant: string?,
		oneShot: string?,
		oneVariant: string?,
		oneLeft: number,
		airTime: number,
		airborne: boolean,
		landLeft: number,
		stopLeft: number,
		idleTimer: number,
		nextIdleAlt: number,
		peakSpeed: number,
		transitions: number,
		pauseTimer: number,
		idleVariant: string?,
		idleLeft: number,
		idleLength: number,
	},
	MotionStateMachine
))

function MotionStateMachine.new(profile: { [string]: any }, seed: number?): Machine
	local self = setmetatable({
		profile = profile,
		rng = Rng.new(seed or 1),
		state = "Idle",
		variant = nil,
		time = 0,
		duration = 0,
		loco = "Idle",
		holdState = nil,
		holdVariant = nil,
		oneShot = nil,
		oneVariant = nil,
		oneLeft = 0,
		airTime = 0,
		airborne = false,
		landLeft = 0,
		stopLeft = 0,
		idleTimer = 0,
		nextIdleAlt = 0,
		peakSpeed = 0,
		transitions = 0,
		pauseTimer = 0,
		idleVariant = nil,
		idleLeft = 0,
		idleLength = 1,
	}, MotionStateMachine)
	self:scheduleIdleAlt()
	return self
end

function MotionStateMachine.scheduleIdleAlt(self: Machine)
	local alt = self.profile.idleAlt
	self.idleTimer = 0
	self.nextIdleAlt = self.rng:range(alt.min, alt.max)
end

-- Estado de un solo uso (Attack, Hurt, Happy, Eat…). Kuachi a veces «se hace el muerto»
-- cuando juega (Happy o Interact). Teselo se resguarda en el caparazón al avisar (Warn).
function MotionStateMachine.trigger(self: Machine, state: string, duration: number?, variant: string?)
	local p = self.profile
	local v = variant
	local d = duration or CreatureMotion.OneShot[state] or 1
	if not v and (state == "Happy" or state == "Interact") and p.playDead and self.rng:chance(p.playDead.chance) then
		v = "PlayDead"
		d = math.max(d, p.playDead.duration)
	end
	if not v and state == "Warn" and p.defend then
		v = p.defend
	end
	self.oneShot = state
	self.oneVariant = v
	self.oneLeft = d
	self.duration = d
end

-- Fija un estado (Stun mientras dura, Defeat, Victory). nil lo suelta.
function MotionStateMachine.hold(self: Machine, state: string?, variant: string?)
	self.holdState = state
	self.holdVariant = variant
end

local function set(self: Machine, state: string, variant: string?)
	if state ~= self.state or variant ~= self.variant then
		self.state = state
		self.variant = variant
		self.time = 0
		self.transitions += 1
	end
end

function MotionStateMachine.update(self: Machine, dt: number, input: Input): string
	local th = CreatureMotion.Thresholds
	local p = self.profile
	local speed = input.speed
	local grounded = input.grounded ~= false
	local vy = input.verticalSpeed or 0
	self.time += dt

	-- Aire
	if not grounded then
		self.airborne = true
		self.airTime += dt
	elseif self.airborne then
		self.airborne = false
		if self.airTime >= th.landMinAir then
			self.landLeft = CreatureMotion.OneShot.Land
		end
		self.airTime = 0
	end
	self.landLeft = math.max(0, self.landLeft - dt)

	-- Locomoción con histéresis
	local loco = self.loco
	local runEnter = p.runSpeed
	local runExit = p.runSpeed * th.runExitFactor
	local yawRate = math.abs(input.yawRate or 0)
	if loco == "Walk" or loco == "Run" then
		self.peakSpeed = math.max(self.peakSpeed, speed)
		if speed < th.walkExit then
			if self.peakSpeed >= th.stopFrom then
				loco = "Stop"
				self.stopLeft = CreatureMotion.OneShot.Stop
			else
				loco = "Idle"
			end
			self.peakSpeed = 0
		elseif loco == "Walk" and speed > runEnter then
			loco = "Run"
		elseif loco == "Run" and speed < runExit then
			loco = "Walk"
		end
	else
		if speed > th.walkEnter then
			loco = if speed > runEnter then "Run" else "Walk"
			self.peakSpeed = speed
		elseif loco == "Stop" then
			self.stopLeft -= dt
			if self.stopLeft <= 0 then
				loco = "Idle"
			end
		elseif loco == "Turn" then
			if yawRate < th.turnExit then
				loco = "Idle"
			end
		elseif loco == "IdleAlt" then
			self.idleLeft -= dt
			if self.idleLeft <= 0 then
				loco = "Idle"
				self:scheduleIdleAlt()
			end
		elseif yawRate > th.turnEnter then
			loco = "Turn"
		else
			loco = "Idle"
			self.idleTimer += dt
			if self.idleTimer >= self.nextIdleAlt then
				loco = "IdleAlt"
				local variants = p.idleAlt.variants
				self.idleVariant = variants[self.rng:int(1, #variants)]
				self.idleLeft = CreatureMotion.IdleAltDuration[self.idleVariant :: string] or 1.5
				self.idleLength = self.idleLeft
			end
		end
	end
	if loco ~= "Idle" and loco ~= "IdleAlt" then
		self.idleTimer = 0
	end
	self.loco = loco

	-- Un solo uso
	if self.oneShot then
		self.oneLeft -= dt
		if self.oneLeft <= 0 then
			self.oneShot = nil
			self.oneVariant = nil
		end
	end

	if self.holdState then
		set(self, self.holdState, self.holdVariant)
	elseif self.oneShot then
		set(self, self.oneShot :: string, self.oneVariant)
	elseif not grounded then
		set(
			self,
			if vy > th.jumpEnter
				then "Jump"
				elseif vy < th.fallEnter then "Fall"
				else self.state == "Jump" and "Jump" or "Fall",
			nil
		)
	elseif self.landLeft > 0 then
		set(self, "Land", nil)
	else
		set(self, loco, if loco == "IdleAlt" then self.idleVariant else nil)
	end
	return self.state
end

return MotionStateMachine
