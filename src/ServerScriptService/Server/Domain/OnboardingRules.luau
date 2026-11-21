--!strict
-- Máquina de estados de los primeros 15 minutos. Cada paso se completa cuando su
-- condición es verdadera en el perfil (tolerante a acciones fuera de orden y a
-- reconexiones: refresh() reconstruye el paso a partir de los datos guardados).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Onboarding = require(Shared.Config.Onboarding)
local Types = require(Shared.Types)

type Profile = Types.Profile

local OnboardingRules = {}

local function hasStarter(p: Profile): boolean
	for _, pet in pairs(p.pets) do
		if pet.acquired.kind == "Starter" then
			return true
		end
	end
	return false
end

local function anyPlaced(p: Profile): boolean
	local lot = p.lots.Hogar
	if not lot then
		return false
	end
	for _, h in pairs(lot.habitats) do
		for _, id in ipairs(h.slots) do
			if id then
				return true
			end
		end
	end
	return false
end

local Done: { [string]: (Profile) -> boolean } = {
	Intro = function(p)
		return p.firsts.intro_finished ~= nil
	end,
	ChooseEgg = hasStarter,
	Hatch = function(p)
		return p.firsts.hatch_completed ~= nil
	end,
	MeetHome = function(p)
		return p.unlocks.LoteHogar ~= nil
	end,
	PlaceInHabitat = function(p)
		return anyPlaced(p)
	end,
	FirstFeed = function(p)
		return p.firsts.first_feed ~= nil
	end,
	FirstBond = function(p)
		return p.firsts.first_bond_gain ~= nil
	end,
	FirstBattle = function(p)
		return p.story.cleared.valle_r1_e1 ~= nil
	end,
	ClaimReward = function(p)
		return p.firsts.first_reward_claimed ~= nil
	end,
}

function OnboardingRules.stepIndex(stepId: string): number
	for i, s in ipairs(Onboarding.Steps) do
		if s.id == stepId then
			return i
		end
	end
	return #Onboarding.Steps
end

-- Avanza mientras el paso actual esté cumplido. Devuelve la lista de pasos completados.
function OnboardingRules.refresh(p: Profile, now: number): { string }
	local completed = {}
	if p.onboarding.completed then
		return completed
	end
	local i = OnboardingRules.stepIndex(p.onboarding.step)
	while i <= #Onboarding.Steps do
		local step = Onboarding.Steps[i]
		if step.id == "Done" then
			p.onboarding.step = "Done"
			p.onboarding.completed = true
			if not p.firsts.tutorial_completed then
				p.firsts.tutorial_completed = now
				table.insert(completed, "tutorial_completed")
			end
			break
		end
		local check = Done[step.id]
		if check and check(p) then
			table.insert(completed, step.id)
			i += 1
			p.onboarding.step = Onboarding.Steps[i].id
		else
			break
		end
	end
	return completed
end

-- Al reconectar no se repite la animación de eclosión (evita quedarse atascado).
function OnboardingRules.onLoad(p: Profile, now: number): { string }
	if p.onboarding.step == "Hatch" and hasStarter(p) then
		p.firsts.hatch_completed = p.firsts.hatch_completed or now
	end
	if p.onboarding.step == "Intro" and hasStarter(p) then
		p.firsts.intro_finished = p.firsts.intro_finished or now
	end
	return OnboardingRules.refresh(p, now)
end

function OnboardingRules.finishIntro(p: Profile, skipped: boolean, now: number)
	if not p.firsts.intro_finished then
		p.firsts.intro_finished = now
		p.onboarding.introSkipped = skipped
	end
	return OnboardingRules.refresh(p, now)
end

return OnboardingRules
