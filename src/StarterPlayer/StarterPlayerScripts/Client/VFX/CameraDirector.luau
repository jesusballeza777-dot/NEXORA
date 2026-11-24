--!strict
-- Cámara de combate que apoya la lectura (Config/VFX.Camera):
-- * base: encuadre de seguimiento de los dos combatientes;
-- * PushIn: acercamiento breve al atacante; Focus: enfoque al objetivo en el impacto;
-- * Nexo: giro corto alrededor del atacante con acercamiento; Boss: presentación del jefe;
-- * shake: sacudida moderada, NUNCA mayor que VFX.Camera.maxShake (0,3 studs).
-- Con movimiento reducido no hay sacudidas ni movimientos de cámara: solo el encuadre base.
-- update(dt) devuelve el CFrame final y, si hay cámara, lo aplica.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))

local VFXSettings = require(script.Parent.VFXSettings)

local CameraDirector = {}
CameraDirector.__index = CameraDirector

type Beat = { kind: string, target: Vector3, t: number, duration: number, amount: number }

function CameraDirector.new(camera: Camera?, opts: { reducedMotion: boolean? }?): any
	return setmetatable({
		camera = camera,
		reduced = opts and opts.reducedMotion,
		base = CFrame.identity,
		look = Vector3.zero,
		beats = {} :: { Beat },
		shakes = {} :: { { amplitude: number, t: number, duration: number } },
		time = 0,
		last = CFrame.identity,
	}, CameraDirector)
end

function CameraDirector.reducedMotion(self: any): boolean
	if self.reduced ~= nil then
		return self.reduced
	end
	return VFXSettings.get().reducedMotion
end

-- Encuadre de seguimiento: desde `from` mirando a `look`
function CameraDirector.setBase(self: any, from: Vector3, look: Vector3)
	self.base = CFrame.lookAt(from, look)
	self.look = look
end

function CameraDirector.beat(self: any, kind: string, target: Vector3, duration: number?)
	if self:reducedMotion() then
		return
	end
	local C = VFX.Camera
	local amount = if kind == "PushIn"
		then C.pushIn.amount
		elseif kind == "Focus" then C.focus.amount
		elseif kind == "Nexo" then C.nexo.pushIn
		else 1
	local d = duration
		or (
			if kind == "PushIn" then C.pushIn.duration elseif kind == "Focus" then C.focus.duration else C.boss.duration
		)
	table.insert(self.beats, { kind = kind, target = target, t = 0, duration = d, amount = amount })
end

function CameraDirector.shake(self: any, amplitude: number, duration: number?)
	if self:reducedMotion() or amplitude <= 0 then
		return
	end
	table.insert(self.shakes, {
		amplitude = math.min(amplitude, VFX.Camera.maxShake),
		t = 0,
		duration = duration or 0.25,
	})
end

function CameraDirector.clear(self: any)
	table.clear(self.beats)
	table.clear(self.shakes)
end

function CameraDirector.busy(self: any): boolean
	return #self.beats > 0
end

-- Desplazamiento de la sacudida en este instante (siempre ≤ maxShake)
function CameraDirector.shakeOffset(self: any): Vector3
	local f = VFX.Camera.shakeFrequency
	local total = Vector3.zero
	local amp = 0
	for _, s in ipairs(self.shakes) do
		local env = 1 - math.clamp(s.t / s.duration, 0, 1)
		amp = math.max(amp, s.amplitude * env * env)
	end
	if amp <= 0 then
		return total
	end
	local t = self.time
	total = Vector3.new(math.sin(t * f * 1.0 + 0.3), math.sin(t * f * 1.3 + 1.1), math.sin(t * f * 0.7 + 2.0))
	local m = total.Magnitude
	if m > 1e-6 then
		total = total / m * amp * math.min(1, m)
	end
	return total
end

function CameraDirector.update(self: any, dt: number): CFrame
	self.time += dt
	local cf = self.base
	local pos, look = cf.Position, self.look
	local keep = {}
	for _, b in ipairs(self.beats) do
		b.t += dt
		local u = math.clamp(b.t / b.duration, 0, 1)
		local env = math.sin(math.pi * u) -- entra y sale suave
		if b.kind == "PushIn" then
			pos = pos:Lerp(b.target, b.amount * env)
		elseif b.kind == "Focus" then
			look = look:Lerp(b.target, 0.5 * env)
			pos = pos:Lerp(b.target, b.amount * env)
		elseif b.kind == "Nexo" then
			local ang = math.rad(VFX.Camera.nexo.orbitDegrees) * env
			local rel = pos - b.target
			local rot = CFrame.Angles(0, ang, 0) * rel
			pos = (b.target + rot):Lerp(b.target, b.amount * env)
			look = look:Lerp(b.target, 0.6 * env)
		elseif b.kind == "Boss" then
			-- De abajo arriba: desde cerca del suelo hasta el encuadre base
			local from = b.target
				+ Vector3.new(VFX.Camera.boss.from[1], VFX.Camera.boss.from[2], VFX.Camera.boss.from[3])
			local up = b.target + Vector3.new(0, VFX.Camera.boss.lookUp, 0)
			local k = 1 - u
			pos = pos:Lerp(from, k)
			look = look:Lerp(up, k)
		end
		if b.t < b.duration then
			table.insert(keep, b)
		end
	end
	self.beats = keep
	local shakes = {}
	for _, s in ipairs(self.shakes) do
		s.t += dt
		if s.t < s.duration then
			table.insert(shakes, s)
		end
	end
	self.shakes = shakes
	local final = CFrame.lookAt(pos, look) + self:shakeOffset()
	self.last = final
	if self.camera then
		self.camera.CFrame = final
	end
	return final
end

return CameraDirector
