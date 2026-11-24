--!strict
-- Seguimiento del acompañante en el plano del suelo (lógica PURA: sin Vector3 ni APIs de
-- motor; recibe dt, las posiciones y una función de raycast inyectada).
--
-- Máquina de estados: Idle (descansa en su sitio) · Follow · CatchUp (corre si se quedó
-- atrás) · Teleport (solo si está a más de `teleport` studs).
-- * Mantiene su sitio a un lado y detrás del jugador (4–6 studs); cambia de lado solo con
--   histéresis (sideSwitch) para no cruzar por delante a cada giro.
-- * Velocidad = velocidad estimada del jugador + corrección proporcional, con límites de
--   aceleración y frenada; el rumbo gira como mucho `turnRate` rad/s; si mira al lado
--   contrario, primero gira y luego acelera.
-- * Nunca entra en el radio personal del jugador: si su camino lo cruza, lo rodea por la
--   tangente y, como garantía, se le empuja fuera del radio.
-- * Obstáculos: un rayo hacia donde va (y «bigotes» a ±35° y ±70°) cada probeInterval;
--   mantiene el lado de esquiva un rato (histéresis) y nunca avanza más allá de un impacto.
-- Convención de Roblox: la criatura mira a +Z; yaw = atan2(x, z).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local CreatureMotion = require(Config:WaitForChild("CreatureMotion"))

local FollowSteering = {}

-- raycast(x, z, dirX, dirZ, length) → distancia al obstáculo o nil
export type Raycast = (number, number, number, number, number) -> number?
export type Owner = { x: number, z: number, fx: number, fz: number }

export type State = {
	x: number,
	z: number,
	yaw: number,
	speed: number,
	vx: number,
	vz: number,
	mode: string,
	side: number, -- +1 derecha del jugador, −1 izquierda
	ownerX: number?,
	ownerZ: number?,
	ownerVX: number,
	ownerVZ: number,
	avoid: number, -- desvío del rumbo por obstáculo (rad)
	avoidSide: number,
	avoidTimer: number,
	probeTimer: number,
	yawRate: number,
	teleported: boolean,
	moving: boolean,
	inertia: number,
}

function FollowSteering.new(x: number, z: number, yaw: number?, inertia: number?): State
	return {
		x = x,
		z = z,
		yaw = yaw or 0,
		speed = 0,
		vx = 0,
		vz = 0,
		mode = "Idle",
		side = 1,
		ownerX = nil,
		ownerZ = nil,
		ownerVX = 0,
		ownerVZ = 0,
		avoid = 0,
		avoidSide = 1,
		avoidTimer = 0,
		probeTimer = 0,
		yawRate = 0,
		teleported = false,
		moving = false,
		inertia = inertia or 1,
	}
end

local function wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

local function len(x: number, z: number): number
	return math.sqrt(x * x + z * z)
end

-- Sitio ideal (lado y atrás) para el lado actual
function FollowSteering.slot(state: State, owner: Owner, params: any?): (number, number)
	local p = params or CreatureMotion.Follow
	local rx, rz = -owner.fz, owner.fx -- derecha del jugador (forward × arriba)
	return owner.x - owner.fx * p.back + rx * p.side * state.side,
		owner.z - owner.fz * p.back + rz * p.side * state.side
end

-- Distancia mínima del segmento (ax,az)→(bx,bz) al punto (px,pz)
local function segmentDistance(ax: number, az: number, bx: number, bz: number, px: number, pz: number): number
	local dx, dz = bx - ax, bz - az
	local l2 = dx * dx + dz * dz
	local t = if l2 > 0 then math.clamp(((px - ax) * dx + (pz - az) * dz) / l2, 0, 1) else 0
	return len(ax + dx * t - px, az + dz * t - pz)
end

local function rotate(x: number, z: number, a: number): (number, number)
	local c, s = math.cos(a), math.sin(a)
	-- giro en el plano XZ con la misma convención que yaw = atan2(x, z)
	return x * c + z * s, -x * s + z * c
end

function FollowSteering.step(state: State, owner: Owner, dt: number, params: any?, raycast: Raycast?): State
	local p = params or CreatureMotion.Follow
	if dt <= 0 then
		return state
	end
	state.teleported = false
	-- Velocidad del jugador estimada a partir de su posición (suavizada)
	if state.ownerX then
		local rvx = (owner.x - (state.ownerX :: number)) / dt
		local rvz = (owner.z - (state.ownerZ :: number)) / dt
		-- Asimétrico: acompaña despacio al arrancar y reacciona al instante si el jugador frena
		local slower = rvx * rvx + rvz * rvz < state.ownerVX * state.ownerVX + state.ownerVZ * state.ownerVZ
		local k = if slower then 1 else math.min(1, dt * 10)
		state.ownerVX += (rvx - state.ownerVX) * k
		state.ownerVZ += (rvz - state.ownerVZ) * k
	end
	state.ownerX, state.ownerZ = owner.x, owner.z
	local ownerSpeed = len(state.ownerVX, state.ownerVZ)

	local ox, oz = state.x - owner.x, state.z - owner.z
	local d = len(ox, oz)

	-- Teletransporte: solo por encima del umbral
	if d > p.teleport then
		local sx, sz = FollowSteering.slot(state, owner, p)
		state.x, state.z = sx, sz
		state.speed, state.vx, state.vz = 0, 0, 0
		state.yaw = math.atan2(owner.fx, owner.fz)
		state.mode = "Teleport"
		state.teleported = true
		state.moving = false
		state.yawRate = 0
		return state
	end

	-- Lado con histéresis: solo cambia si queda claramente del otro lado
	local lateral = ox * -owner.fz + oz * owner.fx
	if lateral * state.side < -p.sideSwitch then
		state.side = -state.side
	end
	local sx, sz = FollowSteering.slot(state, owner, p)
	local tx, tz = sx - state.x, sz - state.z
	local ds = len(tx, tz)

	-- Estados con histéresis
	local mode = state.mode
	if mode == "Teleport" then
		mode = "Follow"
	end
	if mode == "Idle" then
		if ds > p.resumeRadius or ownerSpeed > 1 then
			mode = "Follow"
		end
	elseif mode == "Follow" then
		if d > p.catchUp then
			mode = "CatchUp"
		elseif ds < p.arriveRadius and ownerSpeed < 0.5 and state.speed < 1 then
			mode = "Idle"
		end
	elseif mode == "CatchUp" then
		if d < p.catchUpExit then
			mode = "Follow"
		end
	end
	state.mode = mode

	-- Velocidad deseada
	local dvx, dvz = 0, 0
	if mode ~= "Idle" then
		dvx = state.ownerVX + tx * p.gain
		dvz = state.ownerVZ + tz * p.gain
		local maxSpeed = if mode == "CatchUp" then p.catchUpSpeed else p.maxSpeed
		local m = len(dvx, dvz)
		if m > maxSpeed then
			dvx, dvz = dvx / m * maxSpeed, dvz / m * maxSpeed
		end
		-- Rodea al jugador si el camino al sitio cruza su radio personal
		local R = p.personalRadius
		if d >= R and segmentDistance(state.x, state.z, sx, sz, owner.x, owner.z) < R + 0.5 then
			local m2 = len(dvx, dvz)
			local t1x, t1z = -oz / d, ox / d
			if t1x * tx + t1z * tz < 0 then
				t1x, t1z = -t1x, -t1z
			end
			-- tangente + un poco hacia fuera para no rozar el borde
			dvx = (t1x + ox / d * 0.35) * m2
			dvz = (t1z + oz / d * 0.35) * m2
		end
	end
	local desiredSpeed = len(dvx, dvz)

	-- Obstáculos (rayos inyectados, a ritmo limitado)
	state.avoidTimer = math.max(0, state.avoidTimer - dt)
	state.probeTimer -= dt
	if raycast and desiredSpeed > 0.5 and state.probeTimer <= 0 then
		state.probeTimer = p.probeInterval
		local ux, uz = dvx / desiredSpeed, dvz / desiredSpeed
		local reach = p.probeLength + state.speed * 0.3
		local hit = raycast(state.x, state.z, ux, uz, reach)
		if hit then
			local chosen: number? = nil
			for _, deg in ipairs(p.whiskers) do
				for _, sgn in ipairs({ state.avoidSide, -state.avoidSide }) do
					if not chosen then
						local a = math.rad(deg) * sgn
						local wx, wz = rotate(ux, uz, a)
						if not raycast(state.x, state.z, wx, wz, reach) then
							chosen = a
							state.avoidSide = sgn
						end
					end
				end
			end
			state.avoid = chosen or 0
			state.avoidTimer = p.avoidHold
			if not chosen then
				desiredSpeed *= 0.2
			end
		elseif state.avoidTimer <= 0 then
			state.avoid = 0
		end
	elseif not raycast then
		state.avoid = 0
	end
	if state.avoid ~= 0 then
		dvx, dvz = rotate(dvx, dvz, state.avoid)
	end

	-- Rumbo con giro limitado: si mira al lado contrario, primero gira
	local yawBefore = state.yaw
	local targetSpeed = 0
	if desiredSpeed > 0.1 then
		local want = math.atan2(dvx, dvz)
		local err = wrap(want - state.yaw)
		local maxTurn = p.turnRate * dt
		state.yaw = wrap(state.yaw + math.clamp(err, -maxTurn, maxTurn))
		targetSpeed = desiredSpeed * math.max(0, math.cos(err))
	elseif mode == "Idle" then
		-- En reposo mira despacio hacia donde mira el jugador
		local want = math.atan2(owner.fx, owner.fz)
		local err = wrap(want - state.yaw)
		local maxTurn = p.turnRate * 0.3 * dt
		state.yaw = wrap(state.yaw + math.clamp(err, -maxTurn, maxTurn))
	end
	state.yawRate = wrap(state.yaw - yawBefore) / dt

	-- Aceleración y frenada limitadas (la inercia de la especie las suaviza)
	local inertia = math.max(0.25, state.inertia)
	local fx, fz = math.sin(state.yaw), math.cos(state.yaw)
	-- Frenada de confort: si va hacia el jugador y ya está cerca, frena más fuerte
	local decel = p.decel / inertia
	if d < p.minDistance + 0.5 and d > 1e-6 and (fx * ox + fz * oz) < 0 then
		decel *= p.comfortBrake or 1
		targetSpeed = math.min(targetSpeed, math.max(0, (d - p.minDistance) * p.gain))
	end
	if targetSpeed > state.speed then
		state.speed = math.min(targetSpeed, state.speed + p.accel / inertia * dt)
	else
		state.speed = math.max(targetSpeed, state.speed - decel * dt)
	end
	local stepLen = state.speed * dt
	-- Nunca avanza dentro de un obstáculo
	if raycast and stepLen > 0 then
		local hit = raycast(state.x, state.z, fx, fz, stepLen + p.bodyRadius)
		if hit then
			stepLen = math.max(0, hit - p.bodyRadius)
			state.speed *= 0.5
		end
	end
	state.x += fx * stepLen
	state.z += fz * stepLen
	state.vx, state.vz = fx * state.speed, fz * state.speed

	-- Garantía: fuera del radio personal del jugador
	local px, pz = state.x - owner.x, state.z - owner.z
	local pd = len(px, pz)
	if pd < p.personalRadius then
		local ux, uz
		if pd > 1e-6 then
			ux, uz = px / pd, pz / pd
		else
			ux, uz = -owner.fx, -owner.fz
		end
		state.x = owner.x + ux * p.personalRadius
		state.z = owner.z + uz * p.personalRadius
	end
	state.moving = state.speed > 0.3
	return state
end

return FollowSteering
