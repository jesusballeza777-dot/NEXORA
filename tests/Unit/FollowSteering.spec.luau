--!strict
-- Seguimiento del acompañante (Shared/Domain/FollowSteering): lógica pura con reloj falso.
local T = harness.T
local expect = T.expect
local FollowSteering = harness.get("ReplicatedStorage.Shared.Domain.FollowSteering")
local CreatureMotion = harness.get("ReplicatedStorage.Shared.Config.CreatureMotion")
local P = CreatureMotion.Follow

local DT = 1 / 60

local function dist(s: any, o: any): number
	return math.sqrt((s.x - o.x) ^ 2 + (s.z - o.z) ^ 2)
end

-- Rayo 2D contra cajas alineadas {x0, z0, x1, z1}: distancia al primer impacto o nil
local function boxRaycast(boxes: { { number } })
	return function(x: number, z: number, dx: number, dz: number, length: number): number?
		local best: number? = nil
		for _, b in ipairs(boxes) do
			local tmin, tmax = 0, length
			local ok = true
			for axis = 1, 2 do
				local o = if axis == 1 then x else z
				local d = if axis == 1 then dx else dz
				local lo = if axis == 1 then b[1] else b[2]
				local hi = if axis == 1 then b[3] else b[4]
				if math.abs(d) < 1e-9 then
					if o < lo or o > hi then
						ok = false
					end
				else
					local t1, t2 = (lo - o) / d, (hi - o) / d
					if t1 > t2 then
						t1, t2 = t2, t1
					end
					tmin = math.max(tmin, t1)
					tmax = math.min(tmax, t2)
					if tmin > tmax then
						ok = false
					end
				end
			end
			if ok and (best == nil or tmin < (best :: number)) then
				best = tmin
			end
		end
		return best
	end
end

-- Simula: el jugador sigue `path(t)` → x, z, fx, fz
local function simulate(
	state: any,
	seconds: number,
	path: (number) -> (number, number, number, number),
	raycast: any?,
	onStep: ((any, any, number) -> ())?
)
	local t = 0
	while t < seconds do
		local x, z, fx, fz = path(t)
		local owner = { x = x, z = z, fx = fx, fz = fz }
		FollowSteering.step(state, owner, DT, P, raycast)
		if onStep then
			onStep(state, owner, t)
		end
		t += DT
	end
end

T.describe("FollowSteering · distancia y suavidad", function()
	T.it("mantiene su sitio a un lado y detrás (4–6 studs) andando y parado", function()
		local s = FollowSteering.new(-5, 0)
		local worst = { lo = math.huge, hi = 0 }
		-- 3 s para colocarse, 10 s andando a 16 studs/s en línea recta y 4 s parado
		simulate(
			s,
			17,
			function(t)
				local walk = math.clamp(t - 3, 0, 10)
				return walk * 16, 0, 1, 0
			end,
			nil,
			function(st, owner, t)
				if t > 5 then
					local d = dist(st, owner)
					worst.lo = math.min(worst.lo, d)
					worst.hi = math.max(worst.hi, d)
				end
			end
		)
		if worst.lo < P.minDistance - 0.05 or worst.hi > P.maxDistance + 0.05 then
			error(string.format("distancia fuera de 4–6: %.2f – %.2f", worst.lo, worst.hi))
		end
		expect(s.mode).toBe("Idle")
	end)

	T.it("no oscila en una trayectoria recta (pocos cambios de signo de la velocidad)", function()
		local s = FollowSteering.new(-4, -2.6, math.pi / 2)
		local lastX, lastZ = 0, 0
		local flipsX, flipsZ = 0, 0
		simulate(
			s,
			12,
			function(t)
				return t * 16, 0, 1, 0
			end,
			nil,
			function(st, _, t)
				if t > 2 then
					local sx = if math.abs(st.vx) > 0.05 then (if st.vx > 0 then 1 else -1) else 0
					local sz = if math.abs(st.vz) > 0.05 then (if st.vz > 0 then 1 else -1) else 0
					if sx ~= 0 and lastX ~= 0 and sx ~= lastX then
						flipsX += 1
					end
					if sz ~= 0 and lastZ ~= 0 and sz ~= lastZ then
						flipsZ += 1
					end
					if sx ~= 0 then
						lastX = sx
					end
					if sz ~= 0 then
						lastZ = sz
					end
				end
			end
		)
		expect(flipsX).toBe(0)
		expect(flipsZ <= 2).toBe(true)
	end)

	T.it("parado junto al sitio no tiembla (histéresis de llegada)", function()
		local s = FollowSteering.new(0, 0)
		simulate(s, 3, function()
			return 4, 0, 1, 0
		end)
		local moves = 0
		simulate(
			s,
			5,
			function(t)
				-- el jugador «respira»: ±0,1 studs
				return 4 + math.sin(t * 3) * 0.1, 0, 1, 0
			end,
			nil,
			function(st)
				if st.moving then
					moves += 1
				end
			end
		)
		expect(moves).toBe(0)
		expect(s.mode).toBe("Idle")
	end)

	T.it("limita la aceleración y el ritmo de giro", function()
		local s = FollowSteering.new(0, -5, 0)
		local maxDv, maxTurn = 0, 0
		local prevSpeed, prevYaw = 0, 0
		simulate(
			s,
			4,
			function(t)
				-- el jugador da media vuelta de golpe
				return 0, 0, if t < 1 then 0 else 0, if t < 1 then 1 else -1
			end,
			nil,
			function(st)
				maxDv = math.max(maxDv, math.abs(st.speed - prevSpeed) / DT)
				local dy = math.abs((st.yaw - prevYaw + math.pi) % (2 * math.pi) - math.pi)
				maxTurn = math.max(maxTurn, dy / DT)
				prevSpeed, prevYaw = st.speed, st.yaw
			end
		)
		-- aceleración ≤ accel; frenada ≤ decel (×comfortBrake solo cerca del jugador)
		expect(maxDv <= P.decel * P.comfortBrake + 1e-6).toBe(true)
		expect(maxTurn <= P.turnRate + 1e-3).toBe(true)
	end)
end)

T.describe("FollowSteering · jugador, teletransporte y obstáculos", function()
	T.it("nunca atraviesa al jugador aunque este camine hacia él y lo deje atrás", function()
		-- El acompañante queda delante; el jugador camina hacia él y sigue de largo
		local s = FollowSteering.new(0, 5, math.pi)
		local minD = math.huge
		simulate(
			s,
			6,
			function(t)
				return 0, t * 10 - 3, 0, 1
			end,
			nil,
			function(st, owner)
				minD = math.min(minD, dist(st, owner))
			end
		)
		expect(minD >= P.personalRadius - 1e-6).toBe(true)
		-- Al final queda detrás del jugador
		local _, z = 0, 6 * 10 - 3
		expect(s.z < z).toBe(true)
	end)

	T.it("cuando el sitio queda al otro lado, lo rodea sin entrar en el radio personal", function()
		local s = FollowSteering.new(0, 4, math.pi)
		local minD = math.huge
		simulate(
			s,
			5,
			function()
				return 0, 0, 0, 1 -- su sitio está detrás (z < 0) y él está delante
			end,
			nil,
			function(st, owner)
				minD = math.min(minD, dist(st, owner))
			end
		)
		expect(minD >= P.personalRadius - 1e-6).toBe(true)
		expect(s.z < 0).toBe(true)
	end)

	T.it("solo se teletransporta por encima de 60 studs", function()
		local near = FollowSteering.new(0, -59)
		FollowSteering.step(near, { x = 0, z = 0, fx = 0, fz = 1 }, DT, P)
		expect(near.teleported).toBe(false)
		expect(near.z < -58).toBe(true)
		local far = FollowSteering.new(0, -61)
		FollowSteering.step(far, { x = 0, z = 0, fx = 0, fz = 1 }, DT, P)
		expect(far.teleported).toBe(true)
		expect(math.abs(dist(far, { x = 0, z = 0 }) - math.sqrt(P.back ^ 2 + P.side ^ 2)) < 1e-6).toBe(true)
		-- Persiguiendo al jugador desde lejos, sin superar el umbral, nunca se teletransporta
		local chase = FollowSteering.new(0, -50)
		local teleports = 0
		simulate(
			chase,
			8,
			function(t)
				return 0, t * 4, 0, 1
			end,
			nil,
			function(st)
				if st.teleported then
					teleports += 1
				end
			end
		)
		expect(teleports).toBe(0)
		expect(chase.mode ~= "CatchUp").toBe(true)
	end)

	T.it("rodea un obstáculo simulado sin entrar en él y llega a su sitio", function()
		-- Muro entre el acompañante y su sitio
		local wall = { -4, -9.25, 4, -8.75 }
		local ray = boxRaycast({ wall })
		local s = FollowSteering.new(0, -16, 0)
		local inside = 0
		simulate(
			s,
			8,
			function()
				return 0, 0, 0, 1
			end,
			ray,
			function(st)
				if st.x > wall[1] and st.x < wall[3] and st.z > wall[2] and st.z < wall[4] then
					inside += 1
				end
			end
		)
		expect(inside).toBe(0)
		local sx, sz = FollowSteering.slot(s, { x = 0, z = 0, fx = 0, fz = 1 }, P)
		local d = math.sqrt((s.x - sx) ^ 2 + (s.z - sz) ^ 2)
		if d > 1.5 then
			error(string.format("no llegó: queda a %.2f del sitio (%.2f, %.2f)", d, s.x, s.z))
		end
	end)
end)
