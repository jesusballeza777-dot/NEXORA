--!strict
-- Funciones de paso PURAS de la vida ambiental (Bloque J). Reciben el tiempo y la
-- configuración y devuelven números: sin instancias ni APIs de motor, así se prueban en
-- Lune (tests/Unit/AmbientLife.spec) y el cliente solo traduce el resultado a CFrames.
-- El tiempo es el del servidor (Workspace:GetServerTimeNow): todos los jugadores ven el
-- Gabinete, las aves y los peces en el mismo sitio.

local AmbientMotion = {}

export type Tier = "full" | "half" | "off"

-- LOD por distancia a la cámara (Genesis §9): completo, media frecuencia o nada
function AmbientMotion.lodTier(distance: number, lod: { near: number, far: number }): Tier
	if distance <= lod.near then
		return "full"
	elseif distance <= lod.far then
		return "half"
	end
	return "off"
end

export type Agent = { tier: Tier, cost: number }

-- Reparte el presupuesto de piezas por fotograma. Empieza en un índice que rota (nadie
-- se queda sin turno), los de media frecuencia solo en fotogramas alternos y los
-- apagados nunca. Si un agente solo ya supera el presupuesto, se le deja pasar (uno).
function AmbientMotion.schedule(agents: { Agent }, frame: number, budget: number): { number }
	local out: { number } = {}
	local n = #agents
	if n == 0 then
		return out
	end
	local spent = 0
	local start = frame % n
	for k = 0, n - 1 do
		local i = ((start + k) % n) + 1
		local a = agents[i]
		local due = a.tier == "full" or (a.tier == "half" and (frame + i) % 2 == 0)
		if due then
			if spent + a.cost > budget and #out > 0 then
				break
			end
			spent += a.cost
			table.insert(out, i)
		end
	end
	return out
end

export type GabinetePose = {
	x: number, -- relativo al centro de la ruta (el Gran Nexo)
	z: number,
	lookX: number, -- hacia dónde mira (el frente del Gabinete es −Z del modelo)
	lookZ: number,
	walking: boolean,
	phase: number, -- fase del paso (ciclos completos recorridos)
	bob: number,
}

export type GabineteRoute = { radius: number, speed: number, rest: number, turn: number, stride: number }

local EASE = 2 -- segundos para arrancar y frenar

-- Distancia recorrida tras `tau` segundos de caminata con arranque y frenada suaves
local function walked(tau: number, walkTime: number, v: number): number
	if tau <= 0 then
		return 0
	elseif tau < EASE then
		return v / (2 * EASE) * tau * tau
	elseif tau <= walkTime - EASE then
		return v * (tau - EASE / 2)
	elseif tau < walkTime then
		local rem = walkTime - tau
		return v * (walkTime - EASE) - v / (2 * EASE) * rem * rem
	end
	return v * (walkTime - EASE)
end

function AmbientMotion.gabineteCycle(route: GabineteRoute): (number, number, number)
	local length = 2 * math.pi * route.radius
	local walkTime = length / route.speed + EASE
	return walkTime + route.rest, walkTime, length
end

-- Pose del Gabinete: descansa frente a su despensa (mirando hacia fuera), gira, da una
-- vuelta completa alrededor del árbol (sentido antihorario) y vuelve a girar.
function AmbientMotion.gabinete(t: number, route: GabineteRoute, dockAngle: number): GabinetePose
	local cycle, walkTime, length = AmbientMotion.gabineteCycle(route)
	local tau = t % cycle
	local r = route.radius
	local outX, outZ = math.cos(dockAngle), math.sin(dockAngle)
	local tanX, tanZ = -math.sin(dockAngle), math.cos(dockAngle)
	if tau < route.rest then
		-- Descanso: al llegar gira de la tangente al frente; antes de salir, al revés
		local w = 0
		if tau < route.turn then
			w = 1 - tau / route.turn
		elseif tau > route.rest - route.turn then
			w = (tau - (route.rest - route.turn)) / route.turn
		end
		w = w * w * (3 - 2 * w)
		local lx, lz = outX * (1 - w) + tanX * w, outZ * (1 - w) + tanZ * w
		local m = math.sqrt(lx * lx + lz * lz)
		return {
			x = outX * r,
			z = outZ * r,
			lookX = lx / m,
			lookZ = lz / m,
			walking = false,
			phase = 0,
			bob = math.sin(t * 1.2) * 0.08, -- respira
		}
	end
	local s = walked(tau - route.rest, walkTime, route.speed)
	local a = dockAngle + s / length * 2 * math.pi
	local phase = s / route.stride
	return {
		x = math.cos(a) * r,
		z = math.sin(a) * r,
		lookX = -math.sin(a),
		lookZ = math.cos(a),
		walking = true,
		phase = phase,
		bob = math.abs(math.sin(phase * 2 * math.pi)) * 0.3,
	}
end

-- Pata en marcha trípode: `gait` 0/1 alterna los dos trípodes. Devuelve el giro de la
-- cadera hacia delante (rad, positivo = adelante) y cuánto se levanta la pata (rad).
function AmbientMotion.leg(phase: number, gait: number, walking: boolean): (number, number)
	if not walking then
		return 0, 0
	end
	local p = (phase + gait * 0.5) % 1
	local swing = -0.32 * math.cos(2 * math.pi * p)
	local lift = math.max(0, math.sin(2 * math.pi * p)) * 0.22
	return swing, lift
end

-- Latido del corazón del Nexo (lub-dub): escala y brillo
function AmbientMotion.heart(t: number, cfg: { bpm: number, scale: number }): (number, number)
	local period = 60 / cfg.bpm
	local tau = t % period
	local pulse = math.exp(-((tau / 0.07) ^ 2)) + 0.6 * math.exp(-(((tau - 0.24) / 0.07) ^ 2))
	pulse += math.exp(-(((tau - period) / 0.07) ^ 2)) -- continuidad al cerrar el ciclo
	pulse = math.min(pulse, 1)
	return 1 + cfg.scale * pulse, 0.55 + 0.45 * pulse
end

-- Oscilación de faroles y banderas: cabeceo y alabeo (rad) con ráfagas lentas
function AmbientMotion.sway(t: number, seed: number, cfg: { amplitude: number, speed: number }): (number, number)
	local gust = 0.7 + 0.3 * math.sin(t * 0.37 + seed * 2.3)
	local pitch = cfg.amplitude * gust * math.sin(t * cfg.speed + seed)
	local roll = cfg.amplitude * 0.6 * gust * math.sin(t * cfg.speed * 0.83 + seed * 1.7)
	return pitch, roll
end

-- Canoa o pieza flotante: sube, baja y se ladea un poco
function AmbientMotion.bob(t: number, seed: number): (number, number)
	return math.sin(t * 1.1 + seed) * 0.12, math.sin(t * 0.8 + seed * 1.3) * 0.05
end

export type BirdPose = { x: number, y: number, z: number, lookX: number, lookZ: number, flap: number }

-- Ave `i` de una bandada que circula (relativo al centro de la bandada)
function AmbientMotion.bird(
	t: number,
	i: number,
	flock: { radius: number, count: number, speed: number, seed: number }
): BirdPose
	local dir = if flock.speed >= 0 then 1 else -1
	local a = t * flock.speed + i * (2 * math.pi / flock.count) * 0.35 + flock.seed
	local r = flock.radius * (0.78 + 0.22 * math.sin(i * 1.3 + t * 0.21))
	local glide = math.sin(t * 0.5 + i) > 0.55
	return {
		x = math.cos(a) * r,
		y = 5 * math.sin(t * 0.4 + i * 0.9),
		z = math.sin(a) * r,
		lookX = -math.sin(a) * dir,
		lookZ = math.cos(a) * dir,
		flap = if glide then 0.12 else math.sin(t * 9 + i * 1.7) * 0.6,
	}
end

export type FishPose = { visible: boolean, forward: number, y: number, pitch: number }

-- Salto de un pez cada `period` segundos: arco de ~1,1 s sobre el agua
function AmbientMotion.fish(t: number, cfg: { period: number, offset: number }): FishPose
	local duration = 1.1
	local tau = (t + cfg.offset) % cfg.period
	if tau >= duration then
		return { visible = false, forward = 0, y = -1.2, pitch = 0 }
	end
	local u = tau / duration
	return {
		visible = true,
		forward = (u - 0.5) * 5,
		y = 10.4 * u * (1 - u) - 0.4,
		pitch = math.atan((1 - 2 * u) * 10.4 / 5),
	}
end

export type ButterflyPose = { x: number, y: number, z: number, yaw: number, flap: number }

-- Mariposa `i`: vuelo errático (Lissajous) alrededor del centro del grupo
function AmbientMotion.butterfly(t: number, i: number, group: { radius: number, seed: number }): ButterflyPose
	local k = i + group.seed
	local fx, fz = 0.7 * (1 + i * 0.13), 0.5 * (1 + i * 0.11)
	local x = group.radius * math.sin(t * fx + k)
	local z = group.radius * math.sin(t * fz + k * 2.1)
	local vx = group.radius * fx * math.cos(t * fx + k)
	local vz = group.radius * fz * math.cos(t * fz + k * 2.1)
	return {
		x = x,
		y = 1.6 + 0.8 * math.sin(t * 1.3 + k),
		z = z,
		yaw = math.atan2(-vx, -vz),
		flap = math.sin(t * 14 + k * 2) * 0.9,
	}
end

return AmbientMotion
